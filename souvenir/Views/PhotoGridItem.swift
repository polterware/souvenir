//
//  PhotoGridItem.swift
//  souvenir
//
//  Created by Erick Barcelos on 12/04/25.
//
import SwiftUI
import PhotosUI

struct PhotoGridItem: View {
    let photo: UIImage
    let index: Int
    let ns: Namespace.ID

    var body: some View {
        NavigationLink {
            PhotoEditorView(photo: photo, namespace: ns, matchedID: "photo_\(index)")
                
        } label: {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .matchedTransitionSource(id: "photo_\(index)", in: ns) // Adicione esse modificador
        }
    }
}
