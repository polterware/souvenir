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
                    .renderingMode(.original)
                    .interpolation(.high)
                    .antialiased(true)
                    .matchedGeometryEffect(id: matchedID, in: namespace, isSource: false)
                    .aspectRatio(contentMode: .fit)
                    .zoomable(minZoomScale: 1, doubleTapZoomScale: 3)
                    .animation(.none, value: filtered)
                    .cornerRadius(12)
            } else if let original = image {
                Image(uiImage: original)
                    .resizable()
                    .renderingMode(.original)
                    .interpolation(.high)
                    .antialiased(true)
                    .matchedGeometryEffect(id: matchedID, in: namespace, isSource: false)
                    .aspectRatio(contentMode: .fit)
                    .zoomable(minZoomScale: 1, doubleTapZoomScale: 3)
                    .cornerRadius(12)
            } else {
                Text("Carregue ou selecione uma imagem para editar")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .cornerRadius(12)
        .padding(.horizontal)
        .frame(maxHeight: .infinity)
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
