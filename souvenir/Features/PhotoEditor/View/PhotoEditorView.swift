import SwiftUI
import UIKit


struct PhotoEditorView: View {
    let namespace: Namespace.ID
    let matchedID: String
    var onFinishEditing: ((UIImage?, PhotoEditState?, Bool) -> Void)? // (finalImage, ajustes, salvou?)

    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var bottomSize: CGFloat = 0.25
    @State private var selectedCategory: String = "filters"
    @EnvironmentObject private var colorSchemeManager: ColorSchemeManager
    @StateObject private var viewModel: PhotoEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSaveDiscardModal = false
    @State private var hasChanges = false

    private var initialEditState: PhotoEditState

    init(photo: UIImage, namespace: Namespace.ID, matchedID: String, initialEditState: PhotoEditState? = nil, onFinishEditing: ((UIImage?, PhotoEditState?, Bool) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: PhotoEditorViewModel(image: photo))
        self.namespace = namespace
        self.matchedID = matchedID
        self.onFinishEditing = onFinishEditing
        self.initialEditState = initialEditState ?? PhotoEditState()
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    PhotoEditorMainImage(
                        image: $viewModel.previewBase,
                        filteredImage: $viewModel.previewImage,
                        matchedID: matchedID,
                        namespace: namespace,
                        zoomScale: $zoomScale,
                        lastZoomScale: $lastZoomScale
                    )
                    VStack{
                        ZStack {
                            switch selectedCategory {
                            case "filters":
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
                                    pixelateAmount: $viewModel.editState.pixelateAmount,
                                    colorTint: $viewModel.editState.colorTint,
                                    colorTintIntensity: $viewModel.editState.colorTintIntensity,
                                    duotoneEnabled: $viewModel.editState.duotoneEnabled,
                                    duotoneShadowColor: $viewModel.editState.duotoneShadowColor,
                                    duotoneHighlightColor: $viewModel.editState.duotoneHighlightColor,
                                    duotoneShadowIntensity: $viewModel.editState.duotoneShadowIntensity,
                                    duotoneHighlightIntensity: $viewModel.editState.duotoneHighlightIntensity
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
                        PhotoEditorToolbar(
                            selectedCategory: $selectedCategory,
                            bottomSize: $bottomSize
                        )
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical)
                    .background(colorSchemeManager.primaryColor)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                }
            }
        }
        // Modal de salvar/descartar ao tentar voltar
        .confirmationDialog("Salvar alterações?", isPresented: $showSaveDiscardModal, titleVisibility: .visible) {
            Button("Salvar", role: .none) {
                let finalImage = viewModel.generateFinalImage()
                onFinishEditing?(finalImage, viewModel.editState, true)
                dismiss()
            }
            Button("Descartar", role: .destructive) {
                onFinishEditing?(nil, nil, false)
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Você deseja salvar as alterações feitas nesta edição?")
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            viewModel.editState = initialEditState
        }
        .onChange(of: viewModel.editState) { newValue in
            hasChanges = (newValue != initialEditState)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if hasChanges {
                        showSaveDiscardModal = true
                    } else {
                        onFinishEditing?(nil, nil, false)
                        dismiss()
                    }
                }) {
                    Label("Voltar", systemImage: "chevron.left")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

