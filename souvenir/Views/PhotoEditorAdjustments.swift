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
            if let selected = adjustments.first(where: { $0.id == selectedAdjustment }) {
                Text(selected.label)
                    .font(.caption2)
                    .foregroundColor(colorSchemeManager.secondaryColor)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(adjustments) { adj in
                        Button(action: { selectedAdjustment = adj.id }) {
                            VStack {
                                Image(systemName: adj.icon)
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(selectedAdjustment == adj.id  ? colorSchemeManager.primaryColor : colorSchemeManager.secondaryColor)

                            }
                            .padding(8)
                            .boxBlankStyle(cornerRadius: .infinity, padding: 10)
                            .background(selectedAdjustment == adj.id  ? colorSchemeManager.secondaryColor : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: .infinity))
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Group {
                if selectedAdjustment == "contrast" {
                    ContrastSlider(value: $contrast)
                        .padding(.horizontal)
                } else if selectedAdjustment == "brightness" {
                    BrightnessSlider(value: $brightness)
                        .padding(.horizontal)
                } else if selectedAdjustment == "exposure" {
                    ExposureSlider(value: $exposure)
                        .padding(.horizontal)
                } else if selectedAdjustment == "saturation" {
                    SaturationSlider(value: $saturation)
                        .padding(.horizontal)
                } else if selectedAdjustment == "opacity" {
                    OpacitySlider(value: $opacity)
                        .padding(.horizontal)
                } else if selectedAdjustment == "colorInvert" {
                    ColorInvertSlider(value: $colorInvert)
                        .padding(.horizontal)
                }
            }
           
        }
    }
}

private struct ContrastSlider: View {
    @Binding var value: Float
    var body: some View {
        SlidingRuler(
            value: Binding(
                get: { Double(value) },
                set: { newValue in value = Float(newValue) }
            ),
            in: 0.5...1.5,
            step: 0.3,
            snap: .fraction,
            tick: .fraction
        )
    }
}

private struct BrightnessSlider: View {
    @Binding var value: Float
    var body: some View {
        SlidingRuler(
            value: Binding(
                get: { Double(value) },
                set: { newValue in value = Float(newValue) }
            ),
            in: -0.5...0.5,
            step: 0.1,
            snap: .fraction,
            tick: .fraction
        )
    }
}

private struct ExposureSlider: View {
    @Binding var value: Float
    var body: some View {
        SlidingRuler(
            value: Binding(
                get: { Double(value) },
                set: { newValue in value = Float(newValue) }
            ),
            in: -2.0...2.0,
            step: 0.5,
            snap: .fraction,
            tick: .fraction
        )
    }
}

private struct SaturationSlider: View {
    @Binding var value: Float
    var body: some View {
        SlidingRuler(
            value: Binding(
                get: { Double(value) },
                set: { newValue in value = Float(newValue) }
            ),
            in: 0.0...2.0,
            step: 0.5,
            snap: .fraction,
            tick: .fraction
        )
    }
}

private struct OpacitySlider: View {
    @Binding var value: Float
    var body: some View {
        SlidingRuler(
            value: Binding(
                get: { Double(value) },
                set: { newValue in value = Float(newValue) }
            ),
            in: 0.0...1.0,
            step: 0.1,
            snap: .fraction,
            tick: .fraction
        )
    }
}

private struct ColorInvertSlider: View {
    @Binding var value: Float
    var body: some View {
        SlidingRuler(
            value: Binding(
                get: { Double(value) },
                set: { newValue in value = Float(newValue) }
            ),
            in: 0.0...1.0,
            step: 0.1,
            snap: .fraction,
            tick: .fraction
        )
    }
}

