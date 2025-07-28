// Slider customizado com régua, snap e feedback tátil
struct RulerSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    let format: (Float) -> String
    let tickSpacing: CGFloat
    let majorTickEvery: Int
    let thumbSize: CGFloat
    let rulerHeight: CGFloat
    let sliderHeight: CGFloat
    @GestureState private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var lastFeedbackValue: Int? = nil

    init(
        value: Binding<Float>,
        range: ClosedRange<Float>,
        step: Float = 1.0,
        tickSpacing: CGFloat = 12,
        majorTickEvery: Int = 5,
        thumbSize: CGFloat = 28,
        rulerHeight: CGFloat = 18,
        sliderHeight: CGFloat = 44,
        format: @escaping (Float) -> String = { String(format: "%.0f", $0) }
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.tickSpacing = tickSpacing
        self.majorTickEvery = majorTickEvery
        self.thumbSize = thumbSize
        self.rulerHeight = rulerHeight
        self.sliderHeight = sliderHeight
        self.format = format
    }

    var body: some View {
        GeometryReader { geo in
            let minValue = Int(range.lowerBound / step)
            let maxValue = Int(range.upperBound / step)
            let totalTicks = maxValue - minValue
            let sliderWidth = geo.size.width - thumbSize
            let valueRange = range.upperBound - range.lowerBound
            let percent = CGFloat((value - range.lowerBound) / valueRange)
            let currentX = percent * sliderWidth
            ZStack(alignment: .leading) {
                // Ruler
                HStack(spacing: 0) {
                    ForEach(minValue...maxValue, id: \ .self) { i in
                        let tickValue = Float(i) * step
                        Rectangle()
                            .fill(i % majorTickEvery == 0 ? Color.primary : Color.secondary.opacity(0.5))
                            .frame(width: 2, height: i % majorTickEvery == 0 ? rulerHeight : rulerHeight * 0.6)
                        if i != maxValue {
                            Spacer(minLength: tickSpacing - 2)
                        }
                    }
                }
                .frame(height: rulerHeight)
                .padding(.horizontal, thumbSize/2)
                // Thumb
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Text(format(value))
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                    )
                    .offset(x: currentX)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation.width
                            }
                            .onChanged { gesture in
                                isDragging = true
                                let sliderWidth = geo.size.width - thumbSize
                                let percent = max(0, min(1, (gesture.location.x - thumbSize/2) / sliderWidth))
                                let rawValue = Float(percent) * valueRange + range.lowerBound
                                let snapped = (rawValue / step).rounded() * step
                                let clamped = min(max(snapped, range.lowerBound), range.upperBound)
                                let intValue = Int(clamped / step)
                                if intValue != lastFeedbackValue {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    lastFeedbackValue = intValue
                                }
                                value = clamped
                            }
                            .onEnded { _ in
                                isDragging = false
                                lastFeedbackValue = nil
                            }
                    )
                    .animation(.easeOut(duration: 0.15), value: value)
            }
            .frame(height: sliderHeight)
        }
        .frame(height: sliderHeight)
    }
}
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
        RulerSlider(
            value: $value,
            range: 0.5...1.5,
            step: 0.1,
            tickSpacing: 16,
            majorTickEvery: 5,
            format: { String(format: "%.2f", $0) }
        )
    }
}

private struct BrightnessSlider: View {
    @Binding var value: Float
    var body: some View {
        RulerSlider(
            value: $value,
            range: -0.5...0.5,
            step: 0.1,
            tickSpacing: 16,
            majorTickEvery: 5,
            format: { String(format: "%+.2f", $0) }
        )
    }
}

private struct ExposureSlider: View {
    @Binding var value: Float
    var body: some View {
        RulerSlider(
            value: $value,
            range: -2.0...2.0,
            step: 0.1,
            tickSpacing: 16,
            majorTickEvery: 5,
            format: { String(format: "%+.1f", $0) }
        )
    }
}

private struct SaturationSlider: View {
    @Binding var value: Float
    var body: some View {
        RulerSlider(
            value: $value,
            range: 0.0...2.0,
            step: 0.1,
            tickSpacing: 16,
            majorTickEvery: 5,
            format: { String(format: "%.2f", $0) }
        )
    }
}

private struct VibranceSlider: View {
    @Binding var value: Float
    var body: some View {
        RulerSlider(
            value: $value,
            range: -1.0...1.0,
            step: 0.1,
            tickSpacing: 16,
            majorTickEvery: 5,
            format: { String(format: "%+.2f", $0) }
        )
    }
}

private struct OpacitySlider: View {
    @Binding var value: Float
    var body: some View {
        RulerSlider(
            value: $value,
            range: 0.0...1.0,
            step: 0.01,
            tickSpacing: 16,
            majorTickEvery: 10,
            format: { String(format: "%.2f", $0) }
        )
    }
}

private struct ColorInvertSlider: View {
    @Binding var value: Float
    var body: some View {
        RulerSlider(
            value: $value,
            range: 0.0...1.0,
            step: 0.01,
            tickSpacing: 16,
            majorTickEvery: 10,
            format: { String(format: "%.2f", $0) }
        )
    }
}

private struct PixelateSlider: View {
    @Binding var value: Float
    var body: some View {
        RulerSlider(
            value: $value,
            range: 1.0...40.0,
            step: 1.0,
            tickSpacing: 12,
            majorTickEvery: 5,
            format: { String(format: "%.0f", $0) }
        )
    }
}

private struct ColorTintSlider: View {
    @Binding var value: Float
    var body: some View {
        RulerSlider(
            value: $value,
            range: 0.0...6.0,
            step: 0.1,
            tickSpacing: 16,
            majorTickEvery: 6,
            format: { String(format: "%.2f", $0) }
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
            RulerSlider(
                value: $value,
                range: 0.0...2.0,
                step: 0.01,
                tickSpacing: 16,
                majorTickEvery: 4,
                format: { String(format: "%.2f", $0) }
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
            RulerSlider(
                value: $value,
                range: 0.0...2.0,
                step: 0.01,
                tickSpacing: 16,
                majorTickEvery: 4,
                format: { String(format: "%.2f", $0) }
            )
        }
    }
}
