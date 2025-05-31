//
//  PhotoEditorAdjustments.swift
//  souvenir
//
//  Created by Erick Barcelos on 30/05/25.
//

import SwiftUI

struct PhotoEditorAdjustments: View {
    @Binding var contrast: Float
    @Binding var brightness: Float
    @Binding var exposure: Float
    var body: some View {
        VStack {
            Slider(
                value: Binding(
                    get: { Double(contrast) },
                    set: { newValue in contrast = Float(newValue) }
                ),
                in: 0.5...1.5,
                step: 0.01
            )
            .accentColor(.purple)
            .padding(.horizontal)
            Text("Contraste: \(String(format: "%.2f", contrast))")
                .font(.caption)
                .foregroundColor(.gray)

            Slider(
                value: Binding(
                    get: { Double(brightness) },
                    set: { newValue in brightness = Float(newValue) }
                ),
                in: -0.5...0.5,
                step: 0.01
            )
            .accentColor(.yellow)
            .padding(.horizontal)
            Text("Brilho: \(String(format: "%.2f", brightness))")
                .font(.caption)
                .foregroundColor(.gray)

            Slider(
                value: Binding(
                    get: { Double(exposure) },
                    set: { newValue in exposure = Float(newValue) }
                ),
                in: -2.0...2.0,
                step: 0.01
            )
            .accentColor(.orange)
            .padding(.horizontal)
            Text("Exposição: \(String(format: "%.2f", exposure))")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
