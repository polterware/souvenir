import SwiftUI
import UIKit

struct PhotoEditorView: View {
    let namespace: Namespace.ID
    let matchedID: String

    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var bottomSize: CGFloat = 0.25
    @State private var selectedCategory: String = "filters"
    @EnvironmentObject private var colorSchemeManager: ColorSchemeManager
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
                        image: $viewModel.previewBase, // mostra a original se não houver preview
                        filteredImage: $viewModel.previewImage,
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
                                // Desabilita filtros por enquanto, pois ViewModel foi refatorado e não tem mais image, previewCache ou applyFilter
                                Text("Filtros desabilitados nesta versão").padding()
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            case "edit":
                                PhotoEditorAdjustments(
                                    contrast: $viewModel.editState.contrast,
                                    brightness: $viewModel.editState.brightness,
                                    exposure: $viewModel.editState.exposure,
                                    saturation: $viewModel.editState.saturation,
                                    vibrance: $viewModel.editState.vibrance,
                                    opacity: $viewModel.editState.opacity,
                                    colorInvert: $viewModel.editState.colorInvert,
                                    pixelateAmount: $viewModel.editState.pixelateAmount
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
                    .background(colorSchemeManager.primaryColor)
                    .frame(height: geometry.size.height * 0.28)
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

