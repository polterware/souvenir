//
//  PhotoEditorAdjustments.swift
//  souvenir
//
//  Created by Erick Barcelos on 30/05/25.
//

import SwiftUI

struct PhotoEditorAdjustments: View {
    @Binding var sliderValue: Double
    @Binding var selectedEditOption: String?
    @Binding var brightnessValue: Double
    @Binding var contrastValue: Double
    @Binding var saturationValue: Double
    @Binding var exposureValue: Double
    @Binding var sharpnessValue: Double
    @Binding var grainValue: Double
    @Binding var whitePointValue: Double
    var applyAllEditAdjustments: () -> Void
    var updateOptionValue: (String, Double) -> Void

    let editOptions: [String: (label: String, range: ClosedRange<Double>, step: Double)] = [
        "brightness": ("Brilho", -1.0...1.0, 0.01),
        "contrast": ("Contraste", 0.5...1.5, 0.01),
        "saturation": ("Saturação", 0.0...2.0, 0.01),
        "exposure": ("Exposição", -1.0...1.0, 0.01),
        "sharpness": ("Nitidez", 0.0...2.0, 0.01),
        "grain": ("Granulação", 0.0...0.2, 0.001),
        "whitePoint": ("Branco", 0.5...2.0, 0.01)
    ]

    var body: some View {
        VStack {
            // Opções de ajuste
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(editOptions.keys.sorted(), id: \.self) { key in
                        Button(action: {
                            selectedEditOption = key
                            sliderValue = currentValue(for: key)
                        }) {
                            Text(editOptions[key]?.label ?? key.capitalized)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(selectedEditOption == key ? Color.purple.opacity(0.2) : Color.clear)
                                .cornerRadius(10)
                        }
                    }
                }.padding(.horizontal)
            }

            // Slider para o ajuste selecionado
            if let selected = selectedEditOption,
               let config = editOptions[selected] {
                VStack {
                    Slider(
                        value: Binding(
                            get: { sliderValue },
                            set: { newValue in
                                sliderValue = newValue
                                updateOptionValue(selected, newValue)
                                applyAllEditAdjustments()
                            }
                        ),
                        in: config.range,
                        step: config.step
                    )
                    .accentColor(.purple)
                    .padding(.horizontal)
                    Text("\(config.label): \(String(format: "%.2f", sliderValue))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                Text("Selecione um ajuste")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }

    func currentValue(for option: String) -> Double {
        switch option {
        case "brightness": return brightnessValue
        case "contrast": return contrastValue
        case "saturation": return saturationValue
        case "exposure": return exposureValue
        case "sharpness": return sharpnessValue
        case "grain": return grainValue
        case "whitePoint": return whitePointValue
        default: return 0
        }
    }
}
