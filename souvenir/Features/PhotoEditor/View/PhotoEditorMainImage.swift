//
//  PhotoEditorMainImage.swift
//  souvenir
//
//  Created by Erick Barcelos on 30/05/25.
//

import SwiftUI

struct PhotoEditorMainImage: View {
    // Removido: estados de zoom/pan manual
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
                    .interpolation(.high)
                    .matchedGeometryEffect(id: matchedID, in: namespace, isSource: false)
                    .scaledToFit()
                    .cornerRadius(20)
                    .zoomable(minZoomScale: 1, doubleTapZoomScale: 3)
                    .animation(nil, value: filtered)
            } else if let original = image {
                Image(uiImage: original)
                    .resizable()
                    .interpolation(.high)
                    .matchedGeometryEffect(id: matchedID, in: namespace, isSource: false)
                    .scaledToFit()
                    .cornerRadius(20)
                    .zoomable(minZoomScale: 1, doubleTapZoomScale: 3)
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

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
