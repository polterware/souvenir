//
//  PhotoEditorPresets.swift
//  souvenir
//
//  Created by Erick Barcelos on 30/05/25.
//

import SwiftUI

struct PhotoEditorPresets: View {
    @Binding var image: UIImage?
    var createPresetImage: (String) -> UIImage?
    var applyPreset: (String) -> Void

    // Presets de exemplo
    let presets: [String: String] = [
        "Preset1": "Retrô",
        "Preset2": "Urbano",
        "Preset3": "Vibrante"
    ]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Presets")
                .font(.headline)
                .padding(.leading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(presets.keys), id: \.self) { key in
                        VStack {
                            Button(action: {
                                applyPreset(key)
                            }) {
                                if let preview = createPresetImage(key) {
                                    Image(uiImage: preview)
                                        .resizable()
                                        .aspectRatio(1, contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                } else if let img = image {
                                    Image(uiImage: img)
                                        .resizable()
                                        .aspectRatio(1, contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                }
                            }
                            Text(presets[key] ?? key)
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .frame(width: 60)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 6)
    }
}
