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
        VStack(spacing: 20) {
            if let filtered = filteredImage {
                Image(uiImage: filtered)
                    .resizable()
                    .scaledToFit()
                    .matchedGeometryEffect(id: matchedID, in: namespace, isSource: false)
                    .frame(maxHeight: 300)
                    .scaleEffect(zoomScale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = lastZoomScale * value
                                zoomScale = min(max(newScale, 1.0), 3.0) // adjust limits as needed
                            }
                            .onEnded { _ in
                                lastZoomScale = zoomScale
                            }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 5)
            } else if let original = image {
                Image(uiImage: original)
                    .resizable()
                    .scaledToFit()
                    .matchedGeometryEffect(id: matchedID, in: namespace, isSource: false)
                    .frame(maxHeight: 300)
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
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 5)
            } else {
                Text("Carregue ou selecione uma imagem para editar")
                    .font(.headline)
                    .foregroundColor(.gray)
            }

            Button(action: {
                if let original = image {
                    applyFilter(to: original)
                }
            }) {
                Text("Aplicar Filtro")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(15)
        .shadow(radius: 10)
        .padding()
    }

    func applyFilter(to inputImage: UIImage) {
        let context = CIContext()
        let filter = CIFilter.sepiaTone()
        filter.inputImage = CIImage(image: inputImage)
        filter.intensity = 0.8

        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            filteredImage = UIImage(cgImage: cgImage)
        }
    }
}
