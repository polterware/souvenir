import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct PhotoEditorView: View {
    let namespace: Namespace.ID
    let matchedID: String
    @State private var image: UIImage?
    @State private var filteredImage: UIImage?
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var previewCache: [String: UIImage] = [:]
    private static let sharedCIContext = CIContext()
    @State private var selectedCategory: String = "filters"
    
    
    init(photo: UIImage, namespace: Namespace.ID, matchedID: String) {
        _image = State(initialValue: photo)
        self.namespace = namespace
        self.matchedID = matchedID
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Group {
                        if let filtered = filteredImage {
                            Image(uiImage: filtered)
                                .resizable()
                                .matchedGeometryEffect(id: matchedID, in: namespace, isSource: false)
                                .scaledToFit()
                                .scaleEffect(zoomScale)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let newScale = lastZoomScale * value
                                            zoomScale = min(max(newScale, 1.0), 3.0)
                                        }
                                        .onEnded { _ in
                                            lastZoomScale = zoomScale
                                        }
                                )
                                .cornerRadius(20)
                        } else if let original = image {
                            Image(uiImage: original)
                                .resizable()
                                .matchedGeometryEffect(id: matchedID, in: namespace, isSource: false)
                                .scaledToFit()
                                .scaleEffect(zoomScale)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let newScale = lastZoomScale * value
                                            zoomScale = min(max(newScale, 1.0), 3.0)
                                        }
                                        .onEnded { _ in
                                            lastZoomScale = zoomScale
                                        }
                                )
                                .cornerRadius(20)
                            
                        } else {
                            Text("Carregue ou selecione uma imagem para editar")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: geometry.size.height * 0.75)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            if selectedCategory == "filters" {
                                ForEach(["sepia", "noir", "invert"], id: \.self) { filter in
                                    Button(action: {
                                        applyFilter(filterName: filter)
                                    }) {
                                        if let preview = createFilteredImage(filterName: filter) {
                                            Image(uiImage: preview)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 70, height: 70)
                                                .clipped()
                                                .cornerRadius(10)
                                        } else {
                                            Rectangle()
                                                .fill(Color.secondary)
                                                .frame(width: 70, height: 70)
                                        }
                                    }
                                }
                            } else if selectedCategory == "edit" {
                                ForEach(["crop", "brightness", "contrast"], id: \.self) { option in
                                    Button(action: {
                                        // Adicione aqui a ação específica para a opção de edição, se necessário
                                    }) {
                                        Image(systemName: editOptionIcon(for: option))
                                            .resizable()
                                            .padding()
                                    }
                                    .modifier(BoxBlankStyle(cornerRadius: .infinity))
                                }
                            } else if selectedCategory == "presets" {
                                ForEach(["vintage", "vibrant", "minimal"], id: \.self) { preset in
                                    Button(action: {
                                        applyPreset(presetName: preset)
                                    }) {
                                        if let presetPreview = createPresetImage(presetName: preset) {
                                            Image(uiImage: presetPreview)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 70, height: 70)
                                                .clipped()
                                                .cornerRadius(10)
                                        } else {
                                            Rectangle()
                                                .fill(Color.secondary)
                                                .frame(width: 70, height: 70)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(alignment: .top)
                    .padding()
                
                    // 3. Abaixo dessa scroll view, adicione a scroll view de seleção de categorias:
                    
                        HStack {
                            Spacer()
                            Button(action: {
                                selectedCategory = "filters"
                            }) {
                                VStack {
                                    Image(systemName: "wand.and.stars")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(selectedCategory == "filters" ? .blue : .gray)
                                   
                                }
                            }
                            Spacer()
                            Button(action: {
                                selectedCategory = "edit"
                            }) {
                                VStack {
                                    Image(systemName: "slider.horizontal.3")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(selectedCategory == "edit" ? .blue : .gray)
                                    
                                }
                            }
                            Spacer()
                            Button(action: {
                                selectedCategory = "presets"
                            }) {
                                VStack {
                                    Image(systemName: "paintpalette")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(selectedCategory == "presets" ? .blue : .gray)
                                }
                            }
                            Spacer()
                           
                        }
                        .padding(.horizontal)
                    
             
                
                    Spacer()
                        
                }
                
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    // New applyFilter method that applies different effects based on the filterName
    func applyFilter(filterName: String) {
        guard let inputImage = image else { return }
        let context = PhotoEditorView.sharedCIContext
        var outputImage: CIImage?
        
        switch filterName {
        case "sepia":
            let filter = CIFilter.sepiaTone()
            guard let ciInput = CIImage(image: inputImage.fixOrientation()) else { return }
            filter.inputImage = ciInput
            filter.intensity = 0.8
            outputImage = filter.outputImage
        case "noir":
            let filter = CIFilter.photoEffectNoir()
            guard let ciInput = CIImage(image: inputImage.fixOrientation()) else { return }
            filter.inputImage = ciInput
            outputImage = filter.outputImage
        case "invert":
            let filter = CIFilter.colorInvert()
            guard let ciInput = CIImage(image: inputImage.fixOrientation()) else { return }
            filter.inputImage = ciInput
            outputImage = filter.outputImage
        default:
            outputImage = CIImage(image: inputImage)
        }
        
        if let outputImage = outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            filteredImage = UIImage(cgImage: cgImage)
        }
    }
    
    func createFilteredImage(filterName: String) -> UIImage? {
        guard let inputImage = image else { return nil }
        if let cached = previewCache[filterName] {
            return cached
        }
        let context = PhotoEditorView.sharedCIContext
        var outputImage: CIImage?
        
        guard let thumbImage = thumbnail(for: inputImage, maxDimension: 60) else { return nil }
        
        switch filterName {
        case "sepia":
            let filter = CIFilter.sepiaTone()
            guard let ciInput = CIImage(image: thumbImage.fixOrientation()) else { return nil }
            filter.inputImage = ciInput
            filter.intensity = 0.8
            outputImage = filter.outputImage
        case "noir":
            let filter = CIFilter.photoEffectNoir()
            guard let ciInput = CIImage(image: thumbImage.fixOrientation()) else { return nil }
            filter.inputImage = ciInput
            outputImage = filter.outputImage
        case "invert":
            let filter = CIFilter.colorInvert()
            guard let ciInput = CIImage(image: thumbImage.fixOrientation()) else { return nil }
            filter.inputImage = ciInput
            outputImage = filter.outputImage
        default:
            outputImage = CIImage(image: thumbImage)
        }
        
        if let outputImage = outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            let filtered = UIImage(cgImage: cgImage)
            DispatchQueue.main.async {
                previewCache[filterName] = filtered
            }
            return filtered
        }
        return nil
    }
    
    func applyPreset(presetName: String) {
        guard let inputImage = image else { return }
        let context = PhotoEditorView.sharedCIContext
        var outputImage: CIImage?
        
        switch presetName {
        case "vintage":
            let filter = CIFilter.photoEffectTransfer()
            guard let ciInput = CIImage(image: inputImage.fixOrientation()) else { return }
            filter.inputImage = ciInput
            outputImage = filter.outputImage
        case "vibrant":
            let filter = CIFilter.vibrance()
            guard let ciInput = CIImage(image: inputImage.fixOrientation()) else { return }
            filter.inputImage = ciInput
            filter.amount = 0.8
            outputImage = filter.outputImage
        case "minimal":
            let filter = CIFilter.photoEffectProcess()
            guard let ciInput = CIImage(image: inputImage.fixOrientation()) else { return }
            filter.inputImage = ciInput
            outputImage = filter.outputImage
        default:
            outputImage = CIImage(image: inputImage.fixOrientation())
        }
        
        if let outputImage = outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            filteredImage = UIImage(cgImage: cgImage)
        }
    }

    func createPresetImage(presetName: String) -> UIImage? {
        guard let inputImage = image else { return nil }
        let context = PhotoEditorView.sharedCIContext
        var outputImage: CIImage?
        guard let thumbImage = thumbnail(for: inputImage, maxDimension: 60) else { return nil }
        
        switch presetName {
        case "vintage":
            let filter = CIFilter.photoEffectTransfer()
            guard let ciInput = CIImage(image: thumbImage.fixOrientation()) else { return nil }
            filter.inputImage = ciInput
            outputImage = filter.outputImage
        case "vibrant":
            let filter = CIFilter.vibrance()
            guard let ciInput = CIImage(image: thumbImage.fixOrientation()) else { return nil }
            filter.inputImage = ciInput
            filter.amount = 0.8
            outputImage = filter.outputImage
        case "minimal":
            let filter = CIFilter.photoEffectProcess()
            guard let ciInput = CIImage(image: thumbImage.fixOrientation()) else { return nil }
            filter.inputImage = ciInput
            outputImage = filter.outputImage
        default:
            outputImage = CIImage(image: thumbImage.fixOrientation())
        }
        
        if let outputImage = outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    func thumbnail(for image: UIImage, maxDimension: CGFloat = 60) -> UIImage? {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let thumb = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return thumb
    }
    
    
    // 4. Adicione a função auxiliar editOptionIcon(for:) dentro do struct PhotoEditorView, por exemplo, logo após a função thumbnail(for:):
    func editOptionIcon(for option: String) -> String {
        switch option {
        case "crop":
            return "crop"
        case "brightness":
            return "sun.max"
        case "contrast":
            return "circle.lefthalf.fill"
        default:
            return "slider.horizontal.3"
        }
    }
}

extension UIImage {
    func fixOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? self
    }
}

#Preview{
    ContentView()
}
