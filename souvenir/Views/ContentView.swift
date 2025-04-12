import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var photos: [UIImage] = []
    @State private var showCamera = false
    
    @State private var selectedItems: [PhotosPickerItem] = []
    
    @Namespace private var ns

    var body: some View {
        NavigationStack {
            ZStack {
                PhotosScrollView(photos: $photos,
                                 selectedItems: $selectedItems,
                                 ns: ns)
                CameraButtonView(ns: ns) {
                    showCamera = true
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
        }
    }

    private struct PhotosScrollView: View {
        @Binding var photos: [UIImage]
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
                            PhotosPicker(selection: $selectedItems,
                                         maxSelectionCount: 5,
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
        let ns: Namespace.ID
        var action: () -> Void

        var body: some View {
            VStack {
                Spacer()
                Button(action: action) {
                    Circle()
                        .fill(Color(UIColor.systemGray))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Image(systemName: "eye.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        )

                        .matchedTransitionSource(id: "camera", in: ns)
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
