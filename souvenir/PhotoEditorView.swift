import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI

struct PhotoEditorView: View {
    @State private var image: UIImage?
    @State private var filteredImage: UIImage?
    @State private var selectedItem: PhotosPickerItem? = nil

    var body: some View {
        VStack(spacing: 20) {
            if let filtered = filteredImage {
                Image(uiImage: filtered)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 5)
            } else if let original = image {
                Image(uiImage: original)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 5)
            } else {
                Text("Carregue ou selecione uma imagem para editar")
                    .font(.headline)
                    .foregroundColor(.gray)
            }

            HStack {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Selecionar Foto")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            image = uiImage
                            saveImageToUserDefaults(uiImage)
                        }
                    }
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
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(15)
        .shadow(radius: 10)
        .padding()
        .onAppear {
            loadImageFromUserDefaults()
        }
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

    func saveImageToUserDefaults(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(data, forKey: "savedImage")
        }
    }

    func loadImageFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "savedImage"),
           let savedImage = UIImage(data: data) {
            image = savedImage
        }
    }
}
