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
    @State private var bottomSize: CGFloat = 0.25
    @State private var previewCache: [String: UIImage] = [:]
    private static let sharedCIContext = CIContext()
    @State private var selectedCategory: String = "filters"
    

    // Novas propriedades de estado para os ajustes de edição
    @State private var selectedEditOption: String? = nil
    @State private var sliderValue: Double = 0.0
    
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
                    .frame(maxHeight: .infinity)
                    
                    
                    
                    VStack{
                        HStack {
                            if selectedCategory == "filters" {
                                ScrollView(.horizontal) {
                                    HStack {
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
                                    }
                                }
                            } else if selectedCategory == "edit" {
                                VStack(spacing: 0) {
                                    // Scroll horizontal para os botões de opções de edição
                                    ScrollView(.horizontal) {
                                        HStack {
                                            ForEach(["brightness", "contrast"], id: \.self) { option in
                                                Button(action: {
                                                    selectedEditOption = option
                                                    sliderValue = defaultSliderValue(for: option)
                                                }) {
                                                    Image(systemName: editOptionIcon(for: option))
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 20, height: 20)
                                                        .padding()
                                                }
                                                .modifier(BoxBlankStyle(cornerRadius: .infinity, padding: 0))
                                                .padding(.bottom, 8)
                                                
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .onAppear {
                                        if selectedEditOption == nil {
                                            selectedEditOption = "brightness"
                                            sliderValue = defaultSliderValue(for: "brightness")
                                        }
                                    }
                                    // Define a opção atual (caso nenhuma esteja definida, usa "brightness")
                                    let currentOption = selectedEditOption ?? "brightness"
                                    // Área do slider sempre visível e em full width
                                    VStack(spacing: 8) {
                                        Slider(value: $sliderValue, in: sliderRange(for: currentOption), step: 0.01)
                                            .onChange(of: sliderValue) {_, newValue in
                                                applyEditOptionAdjustment(option: currentOption, value: newValue, useThumbnail: true)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.horizontal)
                                        Text(String(format: "%.2f", sliderValue))
                                            .font(.caption)
                                    }
                                    .animation(.easeInOut, value: sliderValue)
                                }
                                .frame(maxWidth: .infinity, alignment: .top)
                                .animation(.easeInOut, value: selectedEditOption)
                                
                            } else if selectedCategory == "presets" {
                                ScrollView(.horizontal) {
                                    HStack {
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
                            } else if selectedCategory == "crop" {
                                // Exibe uma placeholder para a UI de crop
                                Text("Crop UI placeholder")
                                    .padding()
                            }
                            else if selectedCategory == "sticker" {
                                // Exibe uma placeholder para a UI de crop
                                Text("Sticker UI placeholder")
                                    .padding()
                            }
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                        .padding()
                        
                        // Scroll view de seleção de categorias (barra inferior)
                        HStack {
                            Spacer()
                            Button(action: {
                                selectedCategory = "filters"
                                
                                bottomSize = 0.25
                                
                            }) {
                                VStack {
                                    Image(systemName: "wand.and.stars")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(selectedCategory == "filters" ? .purple : .gray)
                                }
                            }
                            Spacer()
                            Button(action: {
                                selectedCategory = "edit"
                                
                                bottomSize = 0.30
                                
                            }) {
                                VStack {
                                    Image(systemName: "slider.horizontal.3")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(selectedCategory == "edit" ? .purple : .gray)
                                }
                            }
                            Spacer()
                            Button(action: {
                                selectedCategory = "presets"
                                
                                bottomSize = 0.25
                                
                            }) {
                                VStack {
                                    Image(systemName: "paintpalette")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(selectedCategory == "presets" ? .purple : .gray)
                                }
                            }
                            Spacer()
                            Button(action: {
                                selectedCategory = "sticker"
                                
                                bottomSize = 0.25
                                
                            }) {
                                VStack {
                                    Image(systemName: "seal")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(selectedCategory == "sticker" ? .purple : .gray)
                                }
                            }
                            Spacer()
                            Button(action: {
                                selectedCategory = "crop"
                                
                                bottomSize = 0.25
                                
                            }) {
                                VStack {
                                    Image(systemName: "crop")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(selectedCategory == "crop" ? .purple : .gray)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        Spacer()
                        
                    }
                    .frame(height: geometry.size.height * bottomSize, alignment: .top)
                    .animation(.spring, value: bottomSize)
                    
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    // Funções auxiliares para os ajustes de edição com slider
    func sliderRange(for option: String) -> ClosedRange<Double> {
        switch option {
        case "brightness":
            return -1.0...1.0
        case "contrast":
            return 0.5...1.5
        default:
            return 0...1
        }
    }
    
    func defaultSliderValue(for option: String) -> Double {
        switch option {
        case "brightness":
            return 0.0
        case "contrast":
            return 1.0
        default:
            return 0.0
        }
    }
    
    func applyEditOptionAdjustment(option: String, value: Double, useThumbnail: Bool) {
        guard let inputImage = image else { return }
        let context = PhotoEditorView.sharedCIContext
        
        let source = useThumbnail ? thumbnail(for: inputImage, maxDimension: 300) : inputImage
        guard let ciInput = CIImage(image: source?.fixOrientation() ?? inputImage) else { return }
        
        let filter = CIFilter.colorControls()
        filter.inputImage = ciInput
        
        switch option {
        case "brightness":
            filter.brightness = Float(value)
            filter.contrast = 1.0
            filter.saturation = 1.0
        case "contrast":
            filter.contrast = Float(value)
            filter.brightness = 0.0
            filter.saturation = 1.0
        default:
            break
        }
        
        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            filteredImage = UIImage(cgImage: cgImage)
        }
    }
    
    // Métodos de filtros e presets já existentes
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
    
    // Função auxiliar para obter o ícone do ajuste de edição
    func editOptionIcon(for option: String) -> String {
        switch option {
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

#Preview {
    ContentView()
}
