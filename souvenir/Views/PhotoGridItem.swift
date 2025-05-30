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
    let isSelected: Bool
    var onLongPress: () -> Void
    // Novo closure para tratar o toque simples
    var onTap: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        ZStack {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isPressed)
                .matchedTransitionSource(id: "photo_\(index)", in: ns)
            
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                .frame(width: 100, height: 100)
        }
        // Determina a área de toque completa, e unifica o onTap aqui
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(
            minimumDuration: 0.2,
            maximumDistance: 10,
            pressing: { inProgress in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPressed = inProgress
                }
            },
            perform: {
                onLongPress()
            }
        )
    }
}
