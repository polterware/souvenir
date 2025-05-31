//
//  PhotoEditorAdjustments.swift
//  souvenir
//
//  Created by Erick Barcelos on 30/05/25.
//

import SwiftUI
import SlidingRuler

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
    @EnvironmentObject private var colorSchemeManager: ColorSchemeManager

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
                HStack(spacing: 8) {
                    ForEach(adjustments) { adj in
                        Button(action: { selectedAdjustment = adj.id }) {
                            VStack {
                                Image(systemName: adj.icon)
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(selectedAdjustment == adj.id  ? colorSchemeManager.primaryColor : colorSchemeManager.secondaryColor)
                                Text(adj.label)
                                    .font(.caption2)
                                    .foregroundColor(selectedAdjustment == adj.id  ? colorSchemeManager.primaryColor : colorSchemeManager.secondaryColor)
                            }
                            .padding(8)
                            .boxBlankStyle(cornerRadius: 12, padding: 0, width: 80)
                            .background(selectedAdjustment == adj.id  ? colorSchemeManager.secondaryColor : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Group {
                if selectedAdjustment == "contrast" {
                    SlidingRuler(
                        value: Binding(
                            get: { Double(contrast) },
                            set: { newValue in contrast = Float(newValue) }
                        ),
                        in: 0.5...1.5,
                        step: 0.3,
                        snap: .fraction,
                        tick: .fraction,
                    )
                    .padding(.horizontal)
                } else if selectedAdjustment == "brightness" {
                    SlidingRuler(
                        value: Binding(
                            get: { Double(brightness) },
                            set: { newValue in brightness = Float(newValue) }
                        ),
                        in: -0.5...0.5,
                        step: 0.1,
                        snap: .fraction,
                        tick: .fraction,
                    )
                    .padding(.horizontal)
                } else if selectedAdjustment == "exposure" {
                    SlidingRuler(
                        value: Binding(
                            get: { Double(exposure) },
                            set: { newValue in exposure = Float(newValue) }
                        ),
                        in: -2.0...2.0,
                        step: 0.5,
                        snap: .fraction,
                        tick: .fraction,
                    )
                    .padding(.horizontal)
                } else if selectedAdjustment == "saturation" {
                    SlidingRuler(
                        value: Binding(
                            get: { Double(saturation) },
                            set: { newValue in saturation = Float(newValue) }
                        ),
                        in: 0.0...2.0,
                        step: 0.5,
                        snap: .fraction,
                        tick: .fraction,
                    )
                    .padding(.horizontal)
                } else if selectedAdjustment == "opacity" {
                    SlidingRuler(
                        value: Binding(
                            get: { Double(opacity) },
                            set: { newValue in opacity = Float(newValue) }
                        ),
                        in: 0.0...1.0,
                        step: 0.1,
                        snap: .fraction,
                        tick: .fraction,
                    )
                    .padding(.horizontal)
                } else if selectedAdjustment == "colorInvert" {
                    SlidingRuler(
                        value: Binding(
                            get: { Double(colorInvert) },
                            set: { newValue in colorInvert = Float(newValue) }
                        ),
                        in: 0.0...1.0,
                        step: 0.1,
                        snap: .fraction,
                        tick: .fraction,
                    )
                    .padding(.horizontal)
                }
            }
           
        }
    }
}
