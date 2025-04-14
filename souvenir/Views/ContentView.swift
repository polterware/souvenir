import SwiftUI
import PhotosUI
import FluidGradient

struct ContentView: View {
    @State private var photos: [UIImage] = []
    @State private var showCamera = false
    @State private var selectedItems: [PhotosPickerItem] = []

    // Variável para armazenar o índice da foto que será editada
    @State private var selectedPhotoForEditor: UIImage? = nil
    @State private var isSelectionActive: Bool = false
    
    @Namespace private var ns

    var body: some View {
        NavigationStack {
            ZStack {
                PhotosScrollView(
                    photos: $photos,
                    selectedItems: $selectedItems,
                    ns: ns,
                    onPhotoSelected: { index in
                        navigateToPhotoEditor(photo: photos[index])
                    },
                    onPhotosChanged: {
                        savePhotos()
                    },
                    onSelectionChanged: { active in
                        isSelectionActive = active
                    }
                )
                
                if !isSelectionActive {
                    CameraButtonView(ns: ns) {
                        showCamera = true
                    }
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
                    selectedItems.removeAll()
                }
            }
            .onAppear {
                loadPhotos()
            }
            // Navegação para a câmera
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
            // Navegação para o editor de fotos (quando selectedPhotoIndexForEditor não for nil)
            .navigationDestination(isPresented: Binding<Bool>( // Crie um binding a partir de selectedPhotoForEditor
                get: { selectedPhotoForEditor != nil },
                set: { if !$0 { selectedPhotoForEditor = nil } }
            )) {
                if let photo = selectedPhotoForEditor {
                    PhotoEditorView(photo: photo, namespace: ns, matchedID: /* algo */ "")
                }
            }
        }
    }

    /// Função que inicia a navegação para o editor de fotos
    func navigateToPhotoEditor(photo: UIImage) {
        selectedPhotoForEditor = photo
    }

    // ScrollView que exibe e seleciona fotos
    private struct PhotosScrollView: View {
        @Binding var photos: [UIImage]
        @Binding var selectedItems: [PhotosPickerItem]
        @State private var selectedPhotoIndices: Set<Int> = []
        @State private var showShareSheet: Bool = false

        var ns: Namespace.ID
        var onPhotoSelected: (Int) -> Void
        var onPhotosChanged: () -> Void
        var onSelectionChanged: (Bool) -> Void

        // Propriedade computada para acessar as fotos selecionadas
        var selectedPhotos: [UIImage] {
            selectedPhotoIndices.compactMap { index in
                if index < photos.count { return photos[index] }
                else { return nil }
            }
        }

        var body: some View {
            VStack {
                // Grid sempre exibida, com a célula do PhotosPicker (botão “+”) e as fotos existentes
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                        // Remover .zIndex(1) e ExclusiveGesture
                        PhotosPicker(selection: $selectedItems,
                                     maxSelectionCount: 6,
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
                            PhotoGridItem(
                                photo: photos[index],
                                index: index,
                                ns: ns,
                                isSelected: selectedPhotoIndices.contains(index),
                                onLongPress: {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    _ = withAnimation {
                                        selectedPhotoIndices.insert(index)
                                    }
                                },
                                onTap: {
                                    if selectedPhotoIndices.isEmpty {
                                        onPhotoSelected(index)
                                    } else {
                                        withAnimation {
                                            if selectedPhotoIndices.contains(index) {
                                                selectedPhotoIndices.remove(index)
                                            } else {
                                                selectedPhotoIndices.insert(index)
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
                
                // Botões de Share e Delete quando houver seleção
                if !selectedPhotoIndices.isEmpty {
                    HStack {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        Button(action: {
                            for index in selectedPhotoIndices.sorted(by: >) {
                                photos.remove(at: index)
                            }
                            selectedPhotoIndices.removeAll()
                            onPhotosChanged() // Salva as alterações após deletar as fotos
                        }) {
                            Label("Delete", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
            .onChange(of: selectedPhotoIndices) { _, newValue in
                onSelectionChanged(!newValue.isEmpty)
            }
            // Folha de compartilhamento
            .sheet(isPresented: $showShareSheet) {
                ActivityView(activityItems: selectedPhotos)
            }
            
        }
    }

    // Botão que abre a Câmera
    private struct CameraButtonView: View {
        let ns: Namespace.ID
        var action: () -> Void

        var body: some View {
            VStack {
                Spacer()
                Button(action: action) {
                    ZStack {
                        FluidGradient(
                            blobs: [.red, .cyan, .pink],
                            speed: 1.0,
                            blur: 0.7
                        )
                        .background(.blue)
                        .frame(width: 70, height: 70)
                        .cornerRadius(.infinity)

                        Image(systemName: "eye.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
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

struct PhotoGridItem: View {
    let photo: UIImage
    let index: Int
    let ns: Namespace.ID
    let isSelected: Bool
    var onLongPress: () -> Void
    // Novo closure para tratar o toque simples
    var onTap: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        ZStack {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isPressed)
                .matchedTransitionSource(id: "photo_\(index)", in: ns)

            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                .frame(width: 100, height: 100)
        }
        // Determina a área de toque completa, e unifica o onTap aqui
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(
            minimumDuration: 0.2,
            maximumDistance: 10,
            pressing: { inProgress in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPressed = inProgress
                }
            },
            perform: {
                onLongPress()
            }
        )
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}
