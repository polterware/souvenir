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

    init(photo: UIImage, namespace: Namespace.ID, matchedID: String) {
        _image = State(initialValue: photo)
        self.namespace = namespace
        self.matchedID = matchedID
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                // Image display area occupies ~75% of the available height
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
                    } else {
                        Text("Carregue ou selecione uma imagem para editar")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: geometry.size.height * 0.75)
                

                // Horizontal scroll view for filter effects occupying ~15% of height
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        Button("Sepia") {
                            applyFilter(filterName: "sepia")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(8)
                        .foregroundColor(.white)

                        Button("Noir") {
                            applyFilter(filterName: "noir")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(8)
                        .foregroundColor(.white)

                        Button("Invert") {
                            applyFilter(filterName: "invert")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                }
                .frame(height: geometry.size.height * 0.15)
            }
            
        }
    }

    // New applyFilter method that applies different effects based on the filterName
    func applyFilter(filterName: String) {
        guard let inputImage = image else { return }
        let context = CIContext()
        var outputImage: CIImage?

        switch filterName {
        case "sepia":
            let filter = CIFilter.sepiaTone()
            filter.inputImage = CIImage(image: inputImage)
            filter.intensity = 0.8
            outputImage = filter.outputImage
        case "noir":
            let filter = CIFilter.photoEffectNoir()
            filter.inputImage = CIImage(image: inputImage)
            outputImage = filter.outputImage
        case "invert":
            let filter = CIFilter.colorInvert()
            filter.inputImage = CIImage(image: inputImage)
            outputImage = filter.outputImage
        default:
            outputImage = CIImage(image: inputImage)
        }

        if let outputImage = outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            filteredImage = UIImage(cgImage: cgImage)
        }
    }
}

#Preview{
    ContentView()
}
