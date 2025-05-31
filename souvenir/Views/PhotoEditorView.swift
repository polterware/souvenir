import SwiftUI

struct PhotoEditorView: View {
    let namespace: Namespace.ID
    let matchedID: String

    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var bottomSize: CGFloat = 0.25
    @State private var selectedCategory: String = "filters"

    @StateObject private var viewModel: PhotoEditorViewModel

    init(photo: UIImage, namespace: Namespace.ID, matchedID: String) {
        _viewModel = StateObject(wrappedValue: PhotoEditorViewModel(image: photo))
        self.namespace = namespace
        self.matchedID = matchedID
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    PhotoEditorMainImage(
                        image: $viewModel.image,
                        filteredImage: $viewModel.filteredImage,
                        matchedID: matchedID,
                        namespace: namespace,
                        zoomScale: $zoomScale,
                        lastZoomScale: $lastZoomScale
                    )

                    // ÁREA DE OPÇÕES DE CADA CATEGORIA e o toolbar no fundo com animação e altura fixa
                    Spacer() // Empurra tudo para baixo

                    VStack{
                        // Menu de conteúdo animado
                        ZStack {
                            switch selectedCategory {
                            case "filters":
                                PhotoEditorFilters(
                                    image: $viewModel.image,
                                    previewCache: $viewModel.previewCache,
                                    applyFilter: viewModel.applyFilter
                                )
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            case "edit":
                                PhotoEditorAdjustments(
                                    sliderValue: $viewModel.sliderValue,
                                    selectedEditOption: $viewModel.selectedEditOption,
                                    brightnessValue: $viewModel.brightnessValue,
                                    contrastValue: $viewModel.contrastValue,
                                    saturationValue: $viewModel.saturationValue,
                                    exposureValue: $viewModel.exposureValue,
                                    sharpnessValue: $viewModel.sharpnessValue,
                                    grainValue: $viewModel.grainValue,
                                    whitePointValue: $viewModel.whitePointValue,
                                    isEditing: $viewModel.isEditing,
                                    applyAllEditAdjustments: viewModel.applyAllEditAdjustments,
                                    updateOptionValue: viewModel.updateOptionValue
                                )
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            case "sticker":
                                Text("Sticker UI placeholder").padding()
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            default:
                                EmptyView()
                            }
                        }
                        .animation(.easeOut(duration: 0.28), value: selectedCategory)
                        .frame(maxHeight: .infinity)
                        
                        // Toolbar sempre visível
                        PhotoEditorToolbar(
                            selectedCategory: $selectedCategory,
                            bottomSize: $bottomSize
                        )
                        .padding(.bottom, 20)
                        
                        Spacer()
                    }
                    .padding(.vertical)
                    .background(.thinMaterial)
                    .frame(height: geometry.size.height * 0.27)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                }
                
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    ContentView()
}

