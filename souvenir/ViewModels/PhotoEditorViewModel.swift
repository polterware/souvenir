//
//  PhotoEditorViewModel.swift
//  souvenir
//
//  Created by Erick Barcelos on 30/05/25.
//

import SwiftUI
import Combine
import UIKit
import CoreImage

class PhotoEditorViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var filteredImage: UIImage?
    @Published var previewCache: [String: UIImage] = [:]
    @Published var selectedEditOption: String? = nil
    @Published var sliderValue: Double = 0.0
    @Published var brightnessValue: Double = 0.0
    @Published var contrastValue: Double = 1.0
    @Published var saturationValue: Double = 1.0
    @Published var exposureValue: Double = 0.0
    @Published var sharpnessValue: Double = 0.0
    @Published var grainValue: Double = 0.02
    @Published var whitePointValue: Double = 1.0
    @Published var isEditing: Bool = false

    static let sharedCIContext = CIContext()
    private var cancellables = Set<AnyCancellable>()
    private var thumbnail: UIImage? = nil

    init(image: UIImage?) {
        self.image = image
        self.thumbnail = image?.resizeToFit(maxSize: 400)
        // Debounce para sliderValue
        $sliderValue
            .removeDuplicates()
            .debounce(for: .milliseconds(120), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.isEditing {
                    DispatchQueue.global(qos: .userInitiated).async {
                        let preview = self.processAdjustments(useThumbnail: true)
                        DispatchQueue.main.async {
                            self.filteredImage = preview
                        }
                    }
                } else {
                    DispatchQueue.global(qos: .userInitiated).async {
                        let full = self.processAdjustments(useThumbnail: false)
                        DispatchQueue.main.async {
                            self.filteredImage = full
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    // Novo método para processar ajustes
    private func processAdjustments(useThumbnail: Bool) -> UIImage? {
        let baseImage = useThumbnail ? (thumbnail ?? image) : image
        guard let original = baseImage else { return nil }
        var ciImage = CIImage(image: original)
        let colorControls = CIFilter(name: "CIColorControls")!
        colorControls.setValue(ciImage, forKey: kCIInputImageKey)
        colorControls.setValue(brightnessValue, forKey: kCIInputBrightnessKey)
        colorControls.setValue(contrastValue, forKey: kCIInputContrastKey)
        colorControls.setValue(saturationValue, forKey: kCIInputSaturationKey)
        ciImage = colorControls.outputImage
        if let exposure = CIFilter(name: "CIExposureAdjust") {
            exposure.setValue(ciImage, forKey: kCIInputImageKey)
            exposure.setValue(exposureValue, forKey: kCIInputEVKey)
            ciImage = exposure.outputImage
        }
        if let sharpness = CIFilter(name: "CISharpenLuminance") {
            sharpness.setValue(ciImage, forKey: kCIInputImageKey)
            sharpness.setValue(sharpnessValue, forKey: kCIInputSharpnessKey)
            ciImage = sharpness.outputImage
        }
        if grainValue > 0.0, let grain = CIFilter(name: "CINoiseReduction") {
            grain.setValue(ciImage, forKey: kCIInputImageKey)
            grain.setValue(grainValue, forKey: "inputNoiseLevel")
            ciImage = grain.outputImage
        }
        if let white = CIFilter(name: "CIGammaAdjust") {
            white.setValue(ciImage, forKey: kCIInputImageKey)
            white.setValue(whitePointValue, forKey: "inputPower")
            ciImage = white.outputImage
        }
        if let finalCIImage = ciImage,
           let cgimg = PhotoEditorViewModel.sharedCIContext.createCGImage(finalCIImage, from: finalCIImage.extent) {
            return UIImage(cgImage: cgimg)
        }
        return nil
    }

    // Chama applyAllEditAdjustments na main thread após processamento
    private func applyAllEditAdjustmentsOnMainThread() {
        // O processamento é feito em background, mas a atualização da UI deve ser na main thread
        self.applyAllEditAdjustments()
    }

    func applyFilter(_ filterName: String) {
        guard let inputImage = image else { return }
        if filterName == "Original" {
            filteredImage = nil
            return
        }
        let ciImage = CIImage(image: inputImage)
        if let filter = CIFilter(name: filterName) {
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            if let outputImage = filter.outputImage,
               let cgimg = PhotoEditorViewModel.sharedCIContext.createCGImage(outputImage, from: outputImage.extent) {
                filteredImage = UIImage(cgImage: cgimg)
            }
        }
    }

    func applyAllEditAdjustments() {
        guard let original = image else { return }
        var ciImage = CIImage(image: original)
        // Ajuste de brilho, contraste, saturação
        let colorControls = CIFilter(name: "CIColorControls")!
        colorControls.setValue(ciImage, forKey: kCIInputImageKey)
        colorControls.setValue(brightnessValue, forKey: kCIInputBrightnessKey)
        colorControls.setValue(contrastValue, forKey: kCIInputContrastKey)
        colorControls.setValue(saturationValue, forKey: kCIInputSaturationKey)
        ciImage = colorControls.outputImage

        // Exposição
        if let exposure = CIFilter(name: "CIExposureAdjust") {
            exposure.setValue(ciImage, forKey: kCIInputImageKey)
            exposure.setValue(exposureValue, forKey: kCIInputEVKey)
            ciImage = exposure.outputImage
        }

        // Nitidez
        if let sharpness = CIFilter(name: "CISharpenLuminance") {
            sharpness.setValue(ciImage, forKey: kCIInputImageKey)
            sharpness.setValue(sharpnessValue, forKey: kCIInputSharpnessKey)
            ciImage = sharpness.outputImage
        }

        // Granulação
        if grainValue > 0.0, let grain = CIFilter(name: "CINoiseReduction") {
            grain.setValue(ciImage, forKey: kCIInputImageKey)
            grain.setValue(grainValue, forKey: "inputNoiseLevel")
            ciImage = grain.outputImage
        }

        // Branco
        if let white = CIFilter(name: "CIGammaAdjust") {
            white.setValue(ciImage, forKey: kCIInputImageKey)
            white.setValue(whitePointValue, forKey: "inputPower")
            ciImage = white.outputImage
        }

        if let finalCIImage = ciImage,
           let cgimg = PhotoEditorViewModel.sharedCIContext.createCGImage(finalCIImage, from: finalCIImage.extent) {
            filteredImage = UIImage(cgImage: cgimg)
        }
    }

    func updateOptionValue(_ option: String, _ newValue: Double) {
        switch option {
        case "brightness": brightnessValue = newValue
        case "contrast": contrastValue = newValue
        case "saturation": saturationValue = newValue
        case "exposure": exposureValue = newValue
        case "sharpness": sharpnessValue = newValue
        case "grain": grainValue = newValue
        case "whitePoint": whitePointValue = newValue
        default: break
        }
    }

    func createPresetImage(_ presetName: String) -> UIImage? {
        guard let img = image else { return nil }
        let ciImage = CIImage(image: img)
        var output: CIImage?

        switch presetName {
        case "Preset1":
            if let filter = CIFilter(name: "CIPhotoEffectTransfer") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                output = filter.outputImage
            }
        case "Preset2":
            if let filter = CIFilter(name: "CIPhotoEffectChrome") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                output = filter.outputImage
            }
        case "Preset3":
            if let filter = CIFilter(name: "CIPhotoEffectProcess") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                output = filter.outputImage
            }
        default:
            output = ciImage
        }

        if let result = output,
           let cgimg = PhotoEditorViewModel.sharedCIContext.createCGImage(result, from: result.extent) {
            return UIImage(cgImage: cgimg)
        }
        return nil
    }

}
