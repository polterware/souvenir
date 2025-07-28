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
    @Binding var vibrance: Float
    @Binding var opacity: Float
    @Binding var colorInvert: Float
    @Binding var pixelateAmount: Float
    @Binding var colorTint: SIMD4<Float>
    @Binding var colorTintIntensity: Float
    @Binding var duotoneEnabled: Bool
    @Binding var duotoneShadowColor: SIMD4<Float>
    @Binding var duotoneHighlightColor: SIMD4<Float>
    @Binding var duotoneShadowIntensity: Float
    @Binding var duotoneHighlightIntensity: Float
    @State private var selectedAdjustment: String = "contrast"
    @EnvironmentObject private var colorSchemeManager: ColorSchemeManager

    let adjustments: [Adjustment] = [
        Adjustment(id: "contrast", label: "Contraste", icon: "circle.lefthalf.fill"),
        Adjustment(id: "brightness", label: "Brilho", icon: "sun.max"),
        Adjustment(id: "exposure", label: "Exposição", icon: "sunrise"),
        Adjustment(id: "saturation", label: "Saturação", icon: "drop"),
        Adjustment(id: "vibrance", label: "Vibrance", icon: "waveform.path.ecg"),
        Adjustment(id: "opacity", label: "Opacidade", icon: "circle.dashed"),
        Adjustment(id: "colorInvert", label: "Inverter", icon: "circle.righthalf.filled"),
        Adjustment(id: "pixelateAmount", label: "Pixelizar", icon: "rectangle.split.3x3"),
        Adjustment(id: "colorTint", label: "Tint", icon: "paintpalette"),
        Adjustment(id: "duotone", label: "Duotone", icon: "circles.hexagonpath.fill")
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
                        // Define se o botão está "ativo" (valor diferente do padrão)
                        let isActive: Bool = {
                            switch adj.id {
                            case "contrast": return contrast != 1.0
                            case "brightness": return brightness != 0.0
                            case "exposure": return exposure != 0.0
                            case "saturation": return saturation != 1.0
                            case "vibrance": return vibrance != 0.0
                            case "opacity": return opacity != 1.0
                            case "colorInvert": return colorInvert == 1.0
                            case "pixelateAmount": return pixelateAmount != 1.0
                            case "colorTint": return !(colorTint.x == 0.0 && colorTint.y == 0.0 && colorTint.z == 0.0 && colorTint.w == 0.0)
                            case "duotone": return duotoneEnabled
                            default: return false
                            }
                        }()

                        if adj.id == "colorInvert" {
                            Button(action: {
                                // Toggle colorInvert
                                colorInvert = colorInvert == 1.0 ? 0.0 : 1.0
                                selectedAdjustment = adj.id
                            }) {
                                VStack {
                                    Image(systemName: adj.icon)
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(isActive ? colorSchemeManager.primaryColor : colorSchemeManager.secondaryColor)
                                }
                                .padding(8)
                                .boxBlankStyle(cornerRadius: 8, padding: 10)
                                .background(isActive ? colorSchemeManager.secondaryColor : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        } else {
                            Button(action: { selectedAdjustment = adj.id }) {
                                VStack {
                                    Image(systemName: adj.icon)
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(isActive ? colorSchemeManager.primaryColor : colorSchemeManager.secondaryColor)
                                }
                                .padding(8)
                                .boxBlankStyle(cornerRadius: 8, padding: 10)
                                .background(isActive ? colorSchemeManager.secondaryColor : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
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
                } else if selectedAdjustment == "vibrance" {
                    VibranceSlider(value: $vibrance)
                        .padding(.horizontal)
                } else if selectedAdjustment == "opacity" {
                    OpacitySlider(value: $opacity)
                        .padding(.horizontal)
                } else if selectedAdjustment == "colorInvert" {
                    // Não mostra slider, só mostra se está ativado
                    HStack {
                        Image(systemName: "circle.righthalf.filled")
                            .foregroundColor(colorInvert == 1.0 ? colorSchemeManager.primaryColor : colorSchemeManager.secondaryColor)
                        Text(colorInvert == 1.0 ? "Invertido" : "Normal")
                            .foregroundColor(colorSchemeManager.secondaryColor)
                    }
                    .padding(.horizontal)
                } else if selectedAdjustment == "pixelateAmount" {
                    PixelateSlider(value: $pixelateAmount)
                        .padding(.horizontal)
                } else if selectedAdjustment == "colorTint" {
                    HStack(spacing: 16) {
                        ColorPicker("Cor do Tint", selection: Binding(
                            get: {
                                Color(red: Double(colorTint.x), green: Double(colorTint.y), blue: Double(colorTint.z), opacity: Double(colorTint.w))
                            },
                            set: { newColor in
                                if let components = newColor.cgColor?.components, components.count >= 3 {
                                    colorTint = SIMD4<Float>(Float(components[0]), Float(components[1]), Float(components[2]), components.count > 3 ? Float(components[3]) : 1.0)
                                }
                            }
                        ))
                        .frame(width: 48, height: 48)
                        .scaleEffect(1.5)

                        Button(action: {
                            // Remove cor: define como transparente
                            colorTint = SIMD4<Float>(0.0, 0.0, 0.0, 0.0)
                        }) {
                            Text("Remover cor")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                } else if selectedAdjustment == "duotone" {
                    VStack(spacing: 12) {
                        Toggle("Ativar Duotone", isOn: $duotoneEnabled)
                            .padding(.horizontal)
                        DuotoneShadowIntensitySlider(value: $duotoneShadowIntensity)
                            .padding(.horizontal)
                        DuotoneHighlightIntensitySlider(value: $duotoneHighlightIntensity)
                            .padding(.horizontal)
                        HStack {
                            VStack {
                                Text("Sombras")
                                    .font(.caption)
                                    .foregroundColor(colorSchemeManager.secondaryColor)
                                ColorPicker("", selection: Binding(
                                    get: {
                                        Color(red: Double(duotoneShadowColor.x), 
                                             green: Double(duotoneShadowColor.y),
                                             blue: Double(duotoneShadowColor.z),
                                             opacity: Double(duotoneShadowColor.w))
                                    },
                                    set: { newColor in
                                        if let components = newColor.cgColor?.components, components.count >= 3 {
                                            duotoneShadowColor = SIMD4<Float>(
                                                Float(components[0]),
                                                Float(components[1]),
                                                Float(components[2]), 
                                                components.count > 3 ? Float(components[3]) : 1.0
                                            )
                                        }
                                    }
                                ))
                                .labelsHidden()
                            }
                            Spacer()
                            VStack {
                                Text("Destaques")
                                    .font(.caption)
                                    .foregroundColor(colorSchemeManager.secondaryColor)
                                ColorPicker("", selection: Binding(
                                    get: {
                                        Color(red: Double(duotoneHighlightColor.x),
                                             green: Double(duotoneHighlightColor.y),
                                             blue: Double(duotoneHighlightColor.z),
                                             opacity: Double(duotoneHighlightColor.w))
                                    },
                                    set: { newColor in
                                        if let components = newColor.cgColor?.components, components.count >= 3 {
                                            duotoneHighlightColor = SIMD4<Float>(
                                                Float(components[0]),
                                                Float(components[1]), 
                                                Float(components[2]),
                                                components.count > 3 ? Float(components[3]) : 1.0
                                            )
                                        }
                                    }
                                ))
                                .labelsHidden()
                            }
                        }
                        .padding(.horizontal)
                    }
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

private struct VibranceSlider: View {
    @Binding var value: Float
    var body: some View {
        SlidingRuler(
            value: Binding(
                get: { Double(value) },
                set: { newValue in value = Float(newValue) }
            ),
            in: -1.0...1.0,
            step: 0.1,
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

private struct PixelateSlider: View {
    @Binding var value: Float
    var body: some View {
        SlidingRuler(
            value: Binding(
                get: { Double(value) },
                set: { newValue in value = Float(newValue) }
            ),
            in: 1.0...40.0,
            step: 1.0,
            snap: .fraction,
            tick: .fraction
        )
    }
}

private struct ColorTintSlider: View {
    @Binding var value: Float
    var body: some View {
        SlidingRuler(
            value: Binding(
                get: { Double(value) },
                set: { newValue in value = Float(newValue) }
            ),
            in: 0.0...6.0,
            step: 0.5,
            snap: .fraction,
            tick: .fraction
        )
    }
}

private struct DuotoneShadowIntensitySlider: View {
    @Binding var value: Float
    var body: some View {
        VStack(alignment: .leading) {
            Text("Intensidade Sombras")
                .font(.caption)
                .foregroundColor(.secondary)
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
}

private struct DuotoneHighlightIntensitySlider: View {
    @Binding var value: Float
    var body: some View {
        VStack(alignment: .leading) {
            Text("Intensidade Destaques")
                .font(.caption)
                .foregroundColor(.secondary)
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
}
