import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var photos: [UIImage] = []
    @State private var isPhotoCaptureViewPresented = false
    
    // Em vez de um único item:
    // @State private var selectedItem: PhotosPickerItem? = nil
    
    // Agora guardamos vários itens:
    @State private var selectedItems: [PhotosPickerItem] = []
    
    @Namespace private var ns

    var body: some View {
        NavigationView {
            ZStack {
                PhotosScrollView(photos: $photos,
                                 // Em vez de selectedItem: $selectedItem
                                 selectedItems: $selectedItems,
                                 ns: ns)
                CameraButtonView {
                    isPhotoCaptureViewPresented = true
                }
            }
            .navigationTitle("Gallery")
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            photos.append(uiImage)
                        }
                    }
                    savePhotos()
                }
            }
            .onAppear {
                loadPhotos()
            }
            .sheet(isPresented: $isPhotoCaptureViewPresented) {
                PhotoCaptureView(onPhotoCaptured: { photo in
                    photos.append(photo)
                    savePhotos()
                })
            }
        }
    }

    // ScrollView/ LazyVGrid
    private struct PhotosScrollView: View {
        @Binding var photos: [UIImage]
        
        // Em vez de @Binding var selectedItem: PhotosPickerItem?
        @Binding var selectedItems: [PhotosPickerItem]

        var ns: Namespace.ID

        var body: some View {
            VStack {
                if photos.isEmpty {
                    Text("No photos yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            
                            // Note que agora usamos selection: $selectedItems
                            PhotosPicker(selection: $selectedItems,
                                         maxSelectionCount: 5, // ou outro limite que desejar
                                         matching: .images) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(UIColor.systemGray5))
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .foregroundColor(Color(UIColor.systemGray))
                                            .font(.system(size: 30))
                                    )
                                    .frame(width: 100, height: 100)
                            }
                            
                            ForEach(photos.indices, id: \.self) { index in
                                PhotoGridItem(photo: photos[index], index: index, ns: ns)
                            }
                        }
                        .padding()
                        .padding(.bottom, 120)
                    }
                }
            }
        }
    }

    private struct CameraButtonView: View {
        var action: () -> Void

        var body: some View {
            VStack {
                Spacer()
                Button(action: action) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 30))
                        )
                        .shadow(radius: 5)
                }
                .padding(.bottom, 30)
            }
        }
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
