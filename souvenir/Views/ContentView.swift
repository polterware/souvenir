import SwiftUI
import PhotosUI
import FluidGradient

struct ContentView: View {
    @State private var photos: [UIImage] = []
    @State private var showCamera = false
    @State private var selectedItems: [PhotosPickerItem] = []

    // Variável para armazenar o índice da foto que será editada
    @State private var selectedPhotoForEditor: UIImage? = nil

    @Namespace private var ns

    var body: some View {
        NavigationStack {
            ZStack {
                PhotosScrollView(photos: $photos,
                                 selectedItems: $selectedItems,
                                 ns: ns,
                                 onPhotoSelected: { index in
                                     navigateToPhotoEditor(photo: photos[index])
                                 })
                
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

        var ns: Namespace.ID
        // Add this line:
        var onPhotoSelected: (Int) -> Void

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
                                PhotoGridItem(
                                    photo: photos[index],
                                    index: index,
                                    ns: ns,
                                    isSelected: selectedPhotoIndices.contains(index)
                                )
                                // Toque longo para iniciar (ou expandir) o modo de seleção
                                .highPriorityGesture(
                                    LongPressGesture(minimumDuration: 0.5)
                                        .onEnded { _ in
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()

                                            _ = withAnimation {
                                                selectedPhotoIndices.insert(index)
                                            }
                                        }
                                )
                                // Toque simples para navegar ou alternar seleção
                                .simultaneousGesture(
                                    TapGesture()
                                        .onEnded {
                                            if selectedPhotoIndices.isEmpty {
                                                onPhotoSelected(index)
                                            } else {
                                                // Se já estiver no modo de seleção, alterna o item
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
                        .padding(.bottom, 120)
                    }
                }
            }
        }

        // Aqui, precisamos chamar a função de navegação que está no escopo de ContentView.
        // Para isso, você pode mover `PhotosScrollView` para fora de ContentView e receber uma closure de navegação,
        // ou definir a função `navigateToPhotoEditor` como estática, etc.
        //
        // Opção simples: deixar tudo dentro de ContentView (como no exemplo) e garantir que o compiler
        // encontre `navigateToPhotoEditor` no mesmo escopo.
        // Se houver problemas de visibilidade, mova essa função para dentro de PhotosScrollView,
        // ou passe-a como parâmetro em uma closure, ex.:
        // let onEditPhoto: (Int) -> Void
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

    var body: some View {
        ZStack {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .matchedTransitionSource(id: "photo_\(index)", in: ns)

            // Borda que indica seleção
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                .frame(width: 100, height: 100)
        }
    }
}


#Preview {
    ContentView()
}
