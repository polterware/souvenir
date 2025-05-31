//
//  PhotoEditorMainImage.swift
//  souvenir
//
//  Created by Erick Barcelos on 30/05/25.
//

import SwiftUI

struct PhotoEditorMainImage: View {
    @Binding var image: UIImage?
    @Binding var filteredImage: UIImage?
    let matchedID: String
    let namespace: Namespace.ID
    @Binding var zoomScale: CGFloat
    @Binding var lastZoomScale: CGFloat

    var body: some View {
        ZStack {
            if let filtered = filteredImage {
                Image(uiImage: filtered)
                    .resizable()
                    .matchedGeometryEffect(id: matchedID, in: namespace, isSource: false)
                    .scaledToFit()
                    .scaleEffect(zoomScale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = lastZoomScale * value
                                zoomScale = min(max(newScale, 1.0), 3.0)
                            }
                            .onEnded { _ in
                                lastZoomScale = zoomScale
                            }
                    )
                    .cornerRadius(20)
                    .animation(nil, value: filtered) // Evita flicker/swiftui animation
            } else if let original = image {
                Image(uiImage: original)
                    .resizable()
                    .matchedGeometryEffect(id: matchedID, in: namespace, isSource: false)
                    .scaledToFit()
                    .scaleEffect(zoomScale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = lastZoomScale * value
                                zoomScale = min(max(newScale, 1.0), 3.0)
                            }
                            .onEnded { _ in
                                lastZoomScale = zoomScale
                            }
                    )
                    .cornerRadius(20)
            } else {
                Text("Carregue ou selecione uma imagem para editar")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .frame(maxHeight: .infinity)
    }
}
