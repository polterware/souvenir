//
//  PhotoEditorAdjustments.swift
//  souvenir
//
//  Created by Erick Barcelos on 30/05/25.
//

import SwiftUI

struct Adjustment: Identifiable, Hashable {
    let id: String // unique key
    let label: String
    let icon: String
}

struct PhotoEditorAdjustments: View {
    @Binding var contrast: Float
    @Binding var brightness: Float
    @Binding var exposure: Float
    @Binding var saturation: Float
    @Binding var opacity: Float
    @Binding var colorInvert: Float
    @State private var selectedAdjustment: String = "contrast"
    let adjustments: [Adjustment] = [
        Adjustment(id: "contrast", label: "Contraste", icon: "circle.lefthalf.fill"),
        Adjustment(id: "brightness", label: "Brilho", icon: "sun.max"),
        Adjustment(id: "exposure", label: "Exposição", icon: "sunrise"),
        Adjustment(id: "saturation", label: "Saturação", icon: "drop"),
        Adjustment(id: "opacity", label: "Opacidade", icon: "circle.dashed"),
        Adjustment(id: "colorInvert", label: "Inverter", icon: "circle.righthalf.filled")
    ]
    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(adjustments) { adj in
                        Button(action: { selectedAdjustment = adj.id }) {
                            VStack {
                                Image(systemName: adj.icon)
                                    .font(.title2)
                                    .foregroundColor(selectedAdjustment == adj.id ? .accentColor : .gray)
                                Text(adj.label)
                                    .font(.caption2)
                                    .foregroundColor(selectedAdjustment == adj.id ? .accentColor : .gray)
                            }
                            .padding(8)
                            .background(selectedAdjustment == adj.id ? Color.accentColor.opacity(0.15) : Color.clear)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
            Group {
                if selectedAdjustment == "contrast" {
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
                } else if selectedAdjustment == "brightness" {
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
                } else if selectedAdjustment == "exposure" {
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
                } else if selectedAdjustment == "saturation" {
                    Slider(
                        value: Binding(
                            get: { Double(saturation) },
                            set: { newValue in saturation = Float(newValue) }
                        ),
                        in: 0.0...2.0,
                        step: 0.01
                    )
                    .accentColor(.blue)
                    .padding(.horizontal)
                    Text("Saturação: \(String(format: "%.2f", saturation))")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else if selectedAdjustment == "opacity" {
                    Slider(
                        value: Binding(
                            get: { Double(opacity) },
                            set: { newValue in opacity = Float(newValue) }
                        ),
                        in: 0.0...1.0,
                        step: 0.01
                    )
                    .accentColor(.gray)
                    .padding(.horizontal)
                    Text("Opacidade: \(String(format: "%.2f", opacity))")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else if selectedAdjustment == "colorInvert" {
                    Slider(
                        value: Binding(
                            get: { Double(colorInvert) },
                            set: { newValue in colorInvert = Float(newValue) }
                        ),
                        in: 0.0...1.0,
                        step: 0.01
                    )
                    .accentColor(.black)
                    .padding(.horizontal)
                    Text("Inverter: \(String(format: "%.2f", colorInvert))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
