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
import MetalPetal
import os.log

struct PhotoEditState: Equatable {
    var contrast: Float = 1.0
    var brightness: Float = 0.0 // valor padrão neutro
    var exposure: Float = 0.0 // valor padrão neutro
    var saturation: Float = 1.0 // valor padrão neutro
    var opacity: Float = 1.0 // valor padrão neutro (totalmente opaco)
    var colorInvert: Float = 0.0 // valor padrão neutro (sem inversão)
    // Adicione outros parâmetros depois
}

class PhotoEditorViewModel: ObservableObject {
    @Published var previewImage: UIImage?
    @Published var editState = PhotoEditState()
    private var cancellables = Set<AnyCancellable>()
    private var mtiContext: MTIContext? = try? MTIContext(device: MTLCreateSystemDefaultDevice()!)
    public var previewBase: UIImage?

    init(image: UIImage?) {
        self.previewBase = image?.resizeToFit(maxSize: 1024)
        if let base = self.previewBase {
            print("[PhotoEditorViewModel] previewBase size: \(base.size), scale: \(base.scale)")
            if let cg = base.cgImage {
                print("[PhotoEditorViewModel] previewBase alphaInfo: \(cg.alphaInfo), bitsPerPixel: \(cg.bitsPerPixel)")
            }
        } else {
            print("[PhotoEditorViewModel] previewBase is nil after resizeToFit")
        }
        $editState
            .removeDuplicates()
            .debounce(for: .milliseconds(16), scheduler: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] state in
                self?.generatePreview(state: state)
            }
            .store(in: &cancellables)
    }

    private func generatePreview(state: PhotoEditState) {
        guard let base = previewBase?.withAlpha(), let cgImage = base.cgImage, let mtiContext = mtiContext else { return }
        // Log input image info before passing to MetalPetal
        let alphaInfo = cgImage.alphaInfo
        let bitsPerPixel = cgImage.bitsPerPixel
        let bytesPerRow = cgImage.bytesPerRow
        os_log("[PhotoEditorViewModel] Input to MTIImage: alphaInfo: %{public}@, bitsPerPixel: %d, bytesPerRow: %d", String(describing: alphaInfo), bitsPerPixel, bytesPerRow)
        // Assert RGBA8888, premultiplied alpha
        if !(alphaInfo == .premultipliedLast || alphaInfo == .premultipliedFirst) {
            os_log("[PhotoEditorViewModel] Input image is not premultiplied alpha! Skipping preview generation.")
            return
        }
        if bitsPerPixel != 32 {
            os_log("[PhotoEditorViewModel] Input image is not 32bpp RGBA! Skipping preview generation.")
            return
        }
        // Tente isOpaque: true para contornar bug de alphaTypeHandlingRule
        let mtiImage = MTIImage(cgImage: cgImage, options: [.SRGB: false], isOpaque: true)
        // Filtro de saturação (MTISaturationFilter)
        let saturationFilter = MTISaturationFilter()
        saturationFilter.inputImage = mtiImage
        saturationFilter.saturation = state.saturation
        guard let saturatedImage = saturationFilter.outputImage else { return }
        // Filtro de exposição (MTIExposureFilter)
        let exposureFilter = MTIExposureFilter()
        exposureFilter.inputImage = saturatedImage
        exposureFilter.exposure = state.exposure
        guard let exposureImage = exposureFilter.outputImage else { return }
        // Filtro de brilho (MTIBrightnessFilter específico)
        let brightnessFilter = MTIBrightnessFilter()
        brightnessFilter.inputImage = exposureImage
        brightnessFilter.brightness = state.brightness
        guard let brightImage = brightnessFilter.outputImage else { return }
        // Filtro de contraste
        let contrastFilter = MTIContrastFilter()
        contrastFilter.inputImage = brightImage
        contrastFilter.contrast = state.contrast
        guard let contrastImage = contrastFilter.outputImage else { return }
        // Filtro de opacidade (usando MTIOpacityFilter especializado)
        let opacityFilter = MTIOpacityFilter()
        opacityFilter.inputImage = contrastImage
        opacityFilter.opacity = state.opacity
        guard let opacityImage = opacityFilter.outputImage else { return }
        
        // Filtro de inversão de cores (quando colorInvert > 0)
        let finalImage: MTIImage
        if state.colorInvert > 0.0 {
            let invertFilter = MTIColorInvertFilter()
            invertFilter.inputImage = opacityImage
            guard let invertedImage = invertFilter.outputImage else { return }
            
            // Se colorInvert < 1.0, fazemos um blend entre a imagem original e a invertida
            if state.colorInvert < 1.0 {
                let blendFilter = MTIBlendFilter(blendMode: .normal)
                blendFilter.inputImage = invertedImage
                blendFilter.inputBackgroundImage = opacityImage
                blendFilter.intensity = state.colorInvert
                guard let blendedImage = blendFilter.outputImage else { return }
                finalImage = blendedImage
            } else {
                finalImage = invertedImage
            }
        } else {
            finalImage = opacityImage
        }
        
        do {
            let cgimg = try mtiContext.makeCGImage(from: finalImage)
            let uiImage = UIImage(cgImage: cgimg)
            DispatchQueue.main.async {
                self.previewImage = uiImage
            }
            os_log("[PhotoEditorViewModel] Preview image generated successfully.")
        } catch {
            os_log("[PhotoEditorViewModel] Failed to generate preview: %{public}@", String(describing: error))
        }
    }
}
