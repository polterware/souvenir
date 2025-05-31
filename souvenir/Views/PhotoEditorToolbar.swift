//
//  PhotoEditorToolbar.swift
//  souvenir
//
//  Created by Erick Barcelos on 30/05/25.
//

import SwiftUI

struct PhotoEditorToolbar: View {
    @Binding var selectedCategory: String
    @Binding var bottomSize: CGFloat

    var body: some View {
        HStack {
            Spacer()
            CategoryButton(category: "filters", icon: "paintpalette", selectedCategory: $selectedCategory, bottomSize: $bottomSize, targetSize: 0.25)
            Spacer()
            CategoryButton(category: "edit", icon: "slider.horizontal.3", selectedCategory: $selectedCategory, bottomSize: $bottomSize, targetSize: 0.30)
            Spacer()
            CategoryButton(category: "sticker", icon: "seal", selectedCategory: $selectedCategory, bottomSize: $bottomSize, targetSize: 0.25)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct CategoryButton: View {
    let category: String
    let icon: String
    @Binding var selectedCategory: String
    @Binding var bottomSize: CGFloat
    let targetSize: CGFloat

    var body: some View {
        Button(action: {
            selectedCategory = category
            bottomSize = targetSize
        }) {
            VStack {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(selectedCategory == category ? .purple : .gray)
            }
        }
    }
}
