//
//  PhotoEditorFilters.swift
//  souvenir
//
//  Created by Erick Barcelos on 30/05/25.
//

import SwiftUI

struct PhotoEditorFilters: View {
    @Binding var image: UIImage?
    @Binding var previewCache: [String: UIImage]
    var applyFilter: (String) -> Void

    // Lista dos filtros (exemplo)
    let filters: [String] = [
        "Original", "CIPhotoEffectNoir", "CIPhotoEffectChrome",
        "CIPhotoEffectProcess", "CIPhotoEffectTonal", "CIPhotoEffectTransfer"
    ]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Filtros")
                .font(.headline)
                .padding(.leading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filters, id: \.self) { filter in
                        VStack {
                            Button(action: {
                                applyFilter(filter)
                            }) {
                                if let preview = previewCache[filter] {
                                    Image(uiImage: preview)
                                        .resizable()
                                        .aspectRatio(1, contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple, lineWidth: filter == "Original" ? 2 : 0))
                                } else if let img = image {
                                    // Fallback: mostrar miniatura sem filtro
                                    Image(uiImage: img)
                                        .resizable()
                                        .aspectRatio(1, contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                }
                            }
                            Text(filter == "Original" ? "Normal" : filter.replacingOccurrences(of: "CIPhotoEffect", with: ""))
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .frame(width: 60)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 6)
    }
}
