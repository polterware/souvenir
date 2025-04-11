import SwiftUI
import PhotosUI

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ContentView: View {
    @State private var photos: [UIImage] = []
    @State private var isPhotoCaptureViewPresented = false
    @State private var selectedItem: PhotosPickerItem? = nil

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if photos.isEmpty {
                        Text("No photos yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                                ForEach(photos.indices, id: \.self) { index in
                                    NavigationLink(destination: PhotoEditorView(photo: photos[index])) {
                                        Image(uiImage: photos[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }

                VStack {
                    Spacer()
                    Button(action: {
                        isPhotoCaptureViewPresented = true
                    }) {
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
            .navigationTitle("My Photos")
            .navigationBarItems(trailing: PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Image(systemName: "plus")
                    .font(.title)
            })
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        photos.append(uiImage)
                        savePhotos()
                    }
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

    // Save photos to UserDefaults
    func savePhotos() {
        let data = photos.compactMap { $0.jpegData(compressionQuality: 0.8) }
        UserDefaults.standard.set(data, forKey: "savedPhotos")
    }

    // Load photos from UserDefaults
    func loadPhotos() {
        if let data = UserDefaults.standard.array(forKey: "savedPhotos") as? [Data] {
            photos = data.compactMap { UIImage(data: $0) }
        }
    }
}
