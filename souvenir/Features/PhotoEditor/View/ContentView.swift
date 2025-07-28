import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import FluidGradient
import ImageIO

struct ContentView: View {
    struct StoredPhoto {
        let url: URL
        let data: Data
        let image: UIImage
    }
    @State private var photos: [StoredPhoto] = []
    @State private var showCamera = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedPhotoForEditor: UIImage? = nil
    @State private var isSelectionActive: Bool = false

    @Namespace private var ns

    var body: some View {
        NavigationStack {
            ZStack {
                PhotosScrollView(
                    photos: $photos,
                    selectedItems: $selectedItems,
                    ns: ns,
                    onPhotoSelected: { index in
                        navigateToPhotoEditor(photo: photos[index].image)
                    },
                    onPhotosChanged: {
                        savePhotos()
                    },
                    onSelectionChanged: { active in
                        isSelectionActive = active
                    },
                    getImage: { $0.image }
                )

                if !isSelectionActive {
                    CameraButtonView(ns: ns) {
                        showCamera = true
                    }
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    var importedPhotos: [StoredPhoto] = []
                    let storageDir = getPhotoStorageDir()
                    try? FileManager.default.createDirectory(at: storageDir, withIntermediateDirectories: true)
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            let ext = detectImageExtension(data: data)
                            let filename = "photo_\(UUID().uuidString).\(ext)"
                            let url = storageDir.appendingPathComponent(filename)
                            do {
                                try data.write(to: url)
                                if let img = loadUIImageFullQuality(from: data)?.fixOrientation() {
                                    importedPhotos.append(StoredPhoto(url: url, data: data, image: img))
                                }
                            } catch {
                                print("[Import] Falha ao salvar imagem em: \(url.path)")
                            }
                        }
                    }
                    if !importedPhotos.isEmpty {
                        photos.append(contentsOf: importedPhotos)
                        savePhotos()
                    }
                    selectedItems.removeAll()
                }
            }
            .onAppear {
                loadPhotos()
            }
            .navigationDestination(isPresented: $showCamera) {
                PhotoCaptureView(onPhotoCaptured: { photo in
                    // Corrige orientação antes de salvar
                    let orientationFixedPhoto = photo.fixOrientation()
                    
                    if let data = orientationFixedPhoto.pngData() ?? orientationFixedPhoto.jpegData(compressionQuality: 1.0) {
                        let ext = detectImageExtension(data: data)
                        let filename = "photo_\(UUID().uuidString).\(ext)"
                        let url = getPhotoStorageDir().appendingPathComponent(filename)
                        try? FileManager.default.createDirectory(at: getPhotoStorageDir(), withIntermediateDirectories: true)
                        try? data.write(to: url)
                        photos.append(StoredPhoto(url: url, data: data, image: orientationFixedPhoto))
                        savePhotos()
                    }
                })
                .navigationTransition(
                    .zoom(
                        sourceID: "camera",
                        in: ns
                    )
                )
            }
            .navigationDestination(isPresented: Binding<Bool>(
                get: { selectedPhotoForEditor != nil },
                set: { if !$0 { selectedPhotoForEditor = nil } }
            )) {
                if let photo = selectedPhotoForEditor {
                    PhotoEditorView(photo: photo, namespace: ns, matchedID: "")
                }
            }
        }
    }

    func navigateToPhotoEditor(photo: UIImage) {
        // Log image info before editing
        if let cgImage = photo.cgImage {
            print("[navigateToPhotoEditor] size: \(photo.size), alphaInfo: \(cgImage.alphaInfo), bitsPerPixel: \(cgImage.bitsPerPixel)")
        } else {
            print("[navigateToPhotoEditor] No CGImage found!")
        }
        
        // Corrige a orientação antes de qualquer outro processamento
        let orientationFixedPhoto = photo.fixOrientation()
        
        // Always ensure the image is MetalPetal-safe before editing
        if let safePhoto = orientationFixedPhoto.withAlpha() {
            if let cgImage = safePhoto.cgImage {
                print("[navigateToPhotoEditor] SAFE size: \(safePhoto.size), alphaInfo: \(cgImage.alphaInfo), bitsPerPixel: \(cgImage.bitsPerPixel)")
            }
            selectedPhotoForEditor = safePhoto
        } else {
            print("[ContentView] Failed to prepare image for editor (withAlpha failed)")
            // Optionally show an alert here
        }
    }

    func savePhotos() {
        // Salva apenas os paths das imagens, não os dados
        let urls = photos.map { $0.url.path }
        UserDefaults.standard.set(urls, forKey: "savedPhotoPaths")
    }

    func loadPhotos() {
        var loaded: [StoredPhoto] = []
        var validPaths: [String] = []
        if let paths = UserDefaults.standard.array(forKey: "savedPhotoPaths") as? [String] {
            for path in paths {
                let url = URL(fileURLWithPath: path)
                if let data = try? Data(contentsOf: url), let img = loadUIImageFullQuality(from: data) {
                    loaded.append(StoredPhoto(url: url, data: data, image: img))
                    validPaths.append(path)
                }
            }
        }
        photos = loaded
        // Remove paths inválidos do UserDefaults
        if let paths = UserDefaults.standard.array(forKey: "savedPhotoPaths") as? [String], paths != validPaths {
            UserDefaults.standard.set(validPaths, forKey: "savedPhotoPaths")
        }
    }
}

// MARK: - Carregamento de imagem com máxima qualidade
func loadUIImageFullQuality(from data: Data) -> UIImage? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
        return UIImage(data: data)
    }

    // Opções para carregar a imagem já com a orientação EXIF aplicada
    let options: [CFString: Any] = [
        kCGImageSourceShouldAllowFloat: true,
        kCGImageSourceCreateThumbnailFromImageAlways: false,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true
    ]

    // Pega a orientação EXIF
    let propertiesOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    var orientation: UIImage.Orientation = .up
    if let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, propertiesOptions) as? [CFString: Any],
       let exifOrientation = properties[kCGImagePropertyOrientation] as? UInt32 {
        orientation = UIImage.Orientation(exifOrientation: exifOrientation)
    }

    guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary) else {
        return UIImage(data: data)
    }

    let scale: CGFloat = UIScreen.main.scale
    let image = UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
    // Garante que a orientação será .up para todo o app
    return image.fixOrientation()
}

// Extensão para converter EXIF para UIImage.Orientation
extension UIImage.Orientation {
    init(exifOrientation: UInt32) {
        switch exifOrientation {
        case 1: self = .up
        case 2: self = .upMirrored
        case 3: self = .down
        case 4: self = .downMirrored
        case 5: self = .leftMirrored
        case 6: self = .right
        case 7: self = .rightMirrored
        case 8: self = .left
        default: self = .up
        }
    }
}

// MARK: - Helpers para formato original
func detectImageExtension(data: Data) -> String {
    if data.starts(with: [0xFF, 0xD8, 0xFF]) { return "jpg" }
    if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "png" }
    if data.starts(with: [0x00, 0x00, 0x00, 0x18]) || data.starts(with: [0x00, 0x00, 0x00, 0x1C]) { return "heic" }
    return "img"
}

func getPhotoStorageDir() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PhotoStorage")
}

#Preview {
    ContentView()
}
