import SwiftUI
import PhotosUI

struct PhotosScrollView: View {
    @Binding var photos: [UIImage]
    @Binding var selectedItems: [PhotosPickerItem]
    @State private var selectedPhotoIndices: Set<Int> = []
    @State private var showShareSheet: Bool = false

    var ns: Namespace.ID
    var onPhotoSelected: (Int) -> Void
    var onPhotosChanged: () -> Void
    var onSelectionChanged: (Bool) -> Void

    var selectedPhotos: [UIImage] {
        selectedPhotoIndices.compactMap { index in
            if index < photos.count { return photos[index] }
            else { return nil }
        }
    }

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
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
                        onPhotosChanged()
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
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: selectedPhotos)
        }
    }
}
