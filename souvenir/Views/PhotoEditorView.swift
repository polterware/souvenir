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

                    // TOOLBAR (CATEGORIAS)
                    PhotoEditorToolbar(
                        selectedCategory: $selectedCategory,
                        bottomSize: $bottomSize
                    )

                    // ÁREA DE OPÇÕES DE CADA CATEGORIA
                    Group {
                        switch selectedCategory {
                        case "filters":
                            PhotoEditorFilters(
                                image: $viewModel.image,
                                previewCache: $viewModel.previewCache,
                                applyFilter: viewModel.applyFilter
                            )
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
                                applyAllEditAdjustments: viewModel.applyAllEditAdjustments,
                                updateOptionValue: viewModel.updateOptionValue
                            )
                        case "presets":
                            PhotoEditorPresets(
                                image: $viewModel.image,
                                createPresetImage: viewModel.createPresetImage,
                                applyPreset: viewModel.applyPreset
                            )
                        case "crop":
                            Text("Crop UI placeholder").padding()
                        case "sticker":
                            Text("Sticker UI placeholder").padding()
                        default:
                            EmptyView()
                        }
                    }
                    .frame(height: geometry.size.height * bottomSize)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

