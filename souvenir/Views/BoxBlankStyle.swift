//
//  BoxBlankStyle.swift
//  souvenir
//
//  Created by Erick Barcelos on 12/04/25.
//

import SwiftUI

struct BoxBlankStyle: ViewModifier {
    var cornerRadius: CGFloat = 10
    var padding: CGFloat = 16
    var size: CGFloat = 50
    
    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .padding(padding)
            .fontWeight(.bold)
            .cornerRadius(cornerRadius)
            .foregroundColor(.primary)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    .frame(maxWidth: size, maxHeight: size)
            )
    }
}
