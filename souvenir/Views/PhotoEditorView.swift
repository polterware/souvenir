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
    
    @State private var brightnessValue: Double = 0.0
    @State private var contrastValue: Double = 1.0
    @State private var saturationValue: Double = 1.0
    @State private var exposureValue: Double = 0.0
    @State private var sharpnessValue: Double = 0.0
    @State private var grainValue: Double = 0.02
    @State private var whitePointValue: Double = 1.0
    
    init(photo: UIImage, namespace: Namespace.ID, matchedID: String) {
        _image = State(initialValue: photo)
        self.namespace = namespace
        self.matchedID = matchedID
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    ZStack{
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
                        VStack{
                            Spacer()
                            if selectedCategory == "edit" {
                                VStack{
                                    Text(selectedEditOption ?? "brightness")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(10)
                                }
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                .padding()
                                .animation(.easeIn, value: selectedCategory)
                                
                            }
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
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack {
                                            ForEach(["brightness", "contrast", "saturation", "exposure", "sharpness", "grain", "whitePoint"], id: \.self) { option in
                                                Button(action: {
                                                    selectedEditOption = option
                                                    switch option {
                                                    case "brightness":
                                                        sliderValue = brightnessValue
                                                    case "contrast":
                                                        sliderValue = contrastValue
                                                    case "saturation":
                                                        sliderValue = saturationValue
                                                    case "exposure":
                                                        sliderValue = exposureValue
                                                    case "sharpness":
                                                        sliderValue = sharpnessValue
                                                    case "grain":
                                                        sliderValue = grainValue
                                                    case "whitePoint":
                                                        sliderValue = whitePointValue
                                                    default:
                                                        sliderValue = defaultSliderValue(for: option)
                                                    }
                                                }) {
                                                    Image(systemName: editOptionIcon(for: option))
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 20, height: 20)
                                                        .padding()
                                                }
                                                .background(
                                                    Circle()
                                                        .fill(selectedEditOption == option ? Color.primary.opacity(0.15) : Color.clear)
                                                )
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
                                        let snappingThreshold = 0.05
                                        
                                        Slider(
                                            value: $sliderValue,
                                            in: PhotoEditorHelper.sliderRange(for: currentOption),
                                            step: 0.01,
                                            onEditingChanged: { editing in
                                                if !editing {  // Quando o usuário termina de arrastar
                                                    let defaultValue = defaultSliderValue(for: currentOption)
                                                    if abs(sliderValue - defaultValue) < snappingThreshold {
                                                        // Se estiver dentro do intervalo de snapping, "trava" para o valor default
                                                        sliderValue = defaultValue
                                                        updateOptionValue(option: currentOption, value: defaultValue)
                                                    }
                                                    // Aplica os ajustes, usando thumbnail para respostas mais rápidas
                                                    applyAllEditAdjustments(useThumbnail: true)
                                                }
                                            }
                                        )
                                        .onChange(of: sliderValue) {_, newValue in
                                            updateOptionValue(option: currentOption, value: newValue)
                                            applyAllEditAdjustments(useThumbnail: true)
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
        case "saturation":
            return 0.0...2.0
        case "exposure":
            return -2.0...2.0
        case "sharpness":
            return 0.0...2.0
        case "grain":
            return 0.0...0.1
        case "whitePoint":
            return 0.0...1.0
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
        case "saturation":
            return 1.0
        case "exposure":
            return 0.0
        case "sharpness":
            return 0.0
        case "grain":
            return 0.02
        case "whitePoint":
            return 1.0
        default:
            return 0.0
        }
    }
    
    func applyAllEditAdjustments(useThumbnail: Bool = false) {
        guard let inputImage = image else { return }
        let context = PhotoEditorView.sharedCIContext
        let baseImage = useThumbnail ? PhotoEditorHelper.thumbnail(for: inputImage, maxDimension: 300) ?? inputImage : inputImage
        guard var ciImage = CIImage(image: baseImage.fixOrientation()) else { return }
        
        // Aplica ajustes de cor (brilho, contraste, saturação) apenas se os valores forem diferentes dos padrões
        if brightnessValue != 0.0 || contrastValue != 1.0 || saturationValue != 1.0 {
            let colorFilter = CIFilter.colorControls()
            colorFilter.inputImage = ciImage
            colorFilter.brightness = Float(brightnessValue)
            colorFilter.contrast = Float(contrastValue)
            colorFilter.saturation = Float(saturationValue)
            if let output = colorFilter.outputImage {
                ciImage = output
            }
        }
        
        // Aplica exposição somente se o valor for diferente de zero
        if exposureValue != 0.0 {
            let exposureFilter = CIFilter.exposureAdjust()
            exposureFilter.inputImage = ciImage
            exposureFilter.ev = Float(exposureValue)
            if let output = exposureFilter.outputImage {
                ciImage = output
            }
        }
        
        // Aplica nitidez somente se necessário
        if sharpnessValue != 0.0 {
            let sharpnessFilter = CIFilter.unsharpMask()
            sharpnessFilter.inputImage = ciImage
            sharpnessFilter.intensity = Float(sharpnessValue)
            if let output = sharpnessFilter.outputImage {
                ciImage = output
            }
        }
        
        // Aplica grain apenas se o valor ultrapassar um limite mínimo (por exemplo, 0.001)
        if grainValue > 0.001 {
            let noiseFilter = CIFilter.randomGenerator()
            if let noiseImageRaw = noiseFilter.outputImage {
                let noiseImage = noiseImageRaw.cropped(to: ciImage.extent)
                let colorMatrix = CIFilter.colorMatrix()
                colorMatrix.inputImage = noiseImage
                let grain = CGFloat(grainValue)
                colorMatrix.rVector = CIVector(x: grain, y: 0, z: 0, w: 0)
                colorMatrix.gVector = CIVector(x: 0, y: grain, z: 0, w: 0)
                colorMatrix.bVector = CIVector(x: 0, y: 0, z: grain, w: 0)
                colorMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: grain)
                if let tintedNoise = colorMatrix.outputImage {
                    let blendFilter = CIFilter.overlayBlendMode()
                    blendFilter.inputImage = tintedNoise
                    blendFilter.backgroundImage = ciImage
                    if let output = blendFilter.outputImage {
                        ciImage = output
                    }
                }
            }
        }
        
        // Aplica o ajuste de white point apenas se for diferente do padrão (1.0)
        if whitePointValue != 1.0 {
            let whitePointFilter = CIFilter.whitePointAdjust()
            whitePointFilter.inputImage = ciImage
            whitePointFilter.color = CIColor(red: CGFloat(whitePointValue), green: CGFloat(whitePointValue), blue: CGFloat(whitePointValue))
            if let output = whitePointFilter.outputImage {
                ciImage = output
            }
        }
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            filteredImage = UIImage(cgImage: cgImage)
        }
    }
    
    
    func updateOptionValue(option: String, value: Double) {
        switch option {
        case "brightness": brightnessValue = value
        case "contrast": contrastValue = value
        case "saturation": saturationValue = value
        case "exposure": exposureValue = value
        case "sharpness": sharpnessValue = value
        case "grain": grainValue = value
        case "whitePoint": whitePointValue = value
        default: break
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
        
        guard let thumbImage = PhotoEditorHelper.thumbnail(for: inputImage, maxDimension: 60) else { return nil }
        
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
        guard let thumbImage = PhotoEditorHelper.thumbnail(for: inputImage, maxDimension: 60) else { return nil }
        
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
    
    // Função auxiliar para obter o ícone do ajuste de edição
    func editOptionIcon(for option: String) -> String {
        switch option {
        case "brightness":
            return "sun.max"
        case "contrast":
            return "circle.lefthalf.fill"
        case "saturation":
            return "drop"
        case "exposure":
            return "sunrise"
        case "sharpness":
            return "eye"
        case "grain":
            return "circle.grid.cross"
        case "whitePoint":
            return "circle.dotted"
        default:
            return "slider.horizontal.3"
        }
    }
}

#Preview {
    ContentView()
}
