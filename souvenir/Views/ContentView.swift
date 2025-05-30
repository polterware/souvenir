import SwiftUI
import PhotosUI
import FluidGradient

struct ContentView: View {
    @State private var photos: [UIImage] = []
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
                        navigateToPhotoEditor(photo: photos[index])
                    },
                    onPhotosChanged: {
                        savePhotos()
                    },
                    onSelectionChanged: { active in
                        isSelectionActive = active
                    }
                )

                if !isSelectionActive {
                    CameraButtonView(ns: ns) {
                        showCamera = true
                    }
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            photos.append(uiImage)
                        }
                    }
                    savePhotos()
                    selectedItems.removeAll()
                }
            }
            .onAppear {
                loadPhotos()
            }
            .navigationDestination(isPresented: $showCamera) {
                PhotoCaptureView(onPhotoCaptured: { photo in
                    photos.append(photo)
                    savePhotos()
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
        selectedPhotoForEditor = photo
    }

    func savePhotos() {
        let data = photos.compactMap { $0.jpegData(compressionQuality: 0.8) }
        UserDefaults.standard.set(data, forKey: "savedPhotos")
    }

    func loadPhotos() {
        if let data = UserDefaults.standard.array(forKey: "savedPhotos") as? [Data] {
            photos = data.compactMap { UIImage(data: $0) }
        }
    }
}

#Preview {
    ContentView()
}
