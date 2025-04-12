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
                    .frame(height: geometry.size.height * 0.80)

                    // Horizontal scroll view for filter effects occupying remaining height
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
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 16)
                    .background(
                        ZStack(alignment: .top) {
                            Color(UIColor.systemGray6)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(.separator)
                                .alignmentGuide(.top) { d in d[.top] }
                        }
                    )

                }
                
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // New applyFilter method that applies different effects based on the filterName
    func applyFilter(filterName: String) {
        guard let inputImage = image else { return }
        let context = CIContext()
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
