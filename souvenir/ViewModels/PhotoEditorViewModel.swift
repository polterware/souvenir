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
    var vibrance: Float = 0.0 // valor padrão neutro (sem vibrance)
    var opacity: Float = 1.0 // valor padrão neutro (totalmente opaco)
    var colorInvert: Float = 0.0 // valor padrão neutro (sem inversão)
    var pixelateAmount: Float = 1.0 // valor padrão neutro (sem pixelate)
    // Color tint (RGBA, valores de 0 a 1)
    var colorTint: SIMD4<Float> = SIMD4<Float>(0,0,0,0) // padrão: sem cor
    var colorTintIntensity: Float = 1.0 // valor médio para que o slider fique no meio
    // Duotone (usa duas cores para áreas de sombra e luz)
    var duotoneEnabled: Bool = false
    var duotoneShadowColor: SIMD4<Float> = SIMD4<Float>(0.0, 0.2, 1.0, 1.0) // Azul para sombras
    var duotoneHighlightColor: SIMD4<Float> = SIMD4<Float>(1.0, 0.0, 0.0, 1.0) // Vermelho para destaques
    var duotoneShadowIntensity: Float = 0.5 // Intensidade da cor de sombra
    var duotoneHighlightIntensity: Float = 0.5 // Intensidade da cor de destaque
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
        // Filtro de vibrance (MTIVibranceFilter)
        let vibranceImage: MTIImage
        if state.vibrance != 0.0 {
            let vibranceFilter = MTIVibranceFilter()
            vibranceFilter.inputImage = saturatedImage
            vibranceFilter.amount = state.vibrance
            guard let output = vibranceFilter.outputImage else { return }
            vibranceImage = output
        } else {
            vibranceImage = saturatedImage
        }
        // Filtro de exposição (MTIExposureFilter)
        let exposureFilter = MTIExposureFilter()
        exposureFilter.inputImage = vibranceImage
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
        
        // Filtro de pixelate (quando pixelateAmount > 1.0)
        let pixelatedImage: MTIImage
        if state.pixelateAmount > 1.0 {
            let pixelateFilter = MTIPixellateFilter()
            pixelateFilter.inputImage = opacityImage
            // O scale define o tamanho do pixel, quanto maior, mais pixelado
            let scale = max(CGFloat(state.pixelateAmount), 1.0)
            pixelateFilter.scale = CGSize(width: scale, height: scale)
            guard let output = pixelateFilter.outputImage else { return }
            pixelatedImage = output
        } else {
            pixelatedImage = opacityImage
        }
        
        // Filtro de color tint (quando uma cor for selecionada, independente da intensidade)
        let tintedImage: MTIImage
        if state.colorTint.x > 0.0 || state.colorTint.y > 0.0 || state.colorTint.z > 0.0 {
            // Força alpha = 1.0 para a cor do tint
            let color = MTIColor(
                red: Float(state.colorTint.x),
                green: Float(state.colorTint.y),
                blue: Float(state.colorTint.z),
                alpha: 1.0
            )
            let colorImage = MTIImage(color: color, sRGB: false, size: pixelatedImage.size)
            let blendFilter = MTIBlendFilter(blendMode: .overlay) // ou .softLight para um efeito mais suave
            blendFilter.inputImage = pixelatedImage
            blendFilter.inputBackgroundImage = colorImage
            
            // Define uma intensidade mínima de 0.1 quando uma cor é selecionada
            // e permite aumentar até 1.0 conforme o slider
            let minIntensity: Float = 0.1
            let finalIntensity = minIntensity + state.colorTintIntensity * (1.0 - minIntensity)
            
            blendFilter.intensity = finalIntensity
            guard let output = blendFilter.outputImage else { return }
            tintedImage = output
        } else {
            tintedImage = pixelatedImage
        }
        
        // Filtro de Duotone (quando ativado)
        let duotoneImage: MTIImage
        if state.duotoneEnabled {
            // Passo 1: Converter para escala de cinza (luminância) com contraste aprimorado
            // Para escala de cinza, usamos MTISaturationFilter com saturação 0
            let grayscaleFilter = MTISaturationFilter()
            grayscaleFilter.inputImage = tintedImage
            grayscaleFilter.saturation = 0.0 // 0 = escala de cinza, 1 = cores normais
            guard let basicGrayscaleImage = grayscaleFilter.outputImage else { return }
            
            // Opcional: aumentamos levemente o contraste para melhor separação entre sombras e destaques
            let contrastFilter = MTIContrastFilter()
            contrastFilter.inputImage = basicGrayscaleImage
            contrastFilter.contrast = 1.2 // Leve aumento no contraste
            guard let grayscaleImage = contrastFilter.outputImage else { return }
            
            // Passo 2: Criamos duas imagens de cores sólidas para sombras e destaques
            let shadowColor = MTIColor(
                red: Float(state.duotoneShadowColor.x),
                green: Float(state.duotoneShadowColor.y), 
                blue: Float(state.duotoneShadowColor.z),
                alpha: 1.0
            )
            let shadowImage = MTIImage(color: shadowColor, sRGB: false, size: tintedImage.size)
            
            let highlightColor = MTIColor(
                red: Float(state.duotoneHighlightColor.x),
                green: Float(state.duotoneHighlightColor.y), 
                blue: Float(state.duotoneHighlightColor.z),
                alpha: 1.0
            )
            let highlightImage = MTIImage(color: highlightColor, sRGB: false, size: tintedImage.size)
            
            // Passo 3: Abordagem aprimorada de duotone usando Color Dodge para sombras
            // Este método garante que as cores de sombra sejam mais visíveis
            
            // Primeiro criamos uma versão invertida da imagem em escala de cinza para sombras
            let invertFilter = MTIColorInvertFilter()
            invertFilter.inputImage = grayscaleImage
            guard let invertedGray = invertFilter.outputImage else { return }
            
            // Aplicamos o blend de Color Burn entre a cor de sombra e a escala de cinza invertida
            let shadowBlend = MTIBlendFilter(blendMode: .colorBurn)
            shadowBlend.inputImage = invertedGray
            shadowBlend.inputBackgroundImage = shadowImage
            guard let shadowResult = shadowBlend.outputImage else { return }
            
            // Invertemos novamente para obter as sombras corretamente
            let finalInvertFilter = MTIColorInvertFilter()
            finalInvertFilter.inputImage = shadowResult
            guard let shadowFinal = finalInvertFilter.outputImage else { return }
            
            // Para destaques, usamos Screen blend que funciona bem com áreas claras
            let highlightBlend = MTIBlendFilter(blendMode: .screen)
            highlightBlend.inputImage = grayscaleImage
            highlightBlend.inputBackgroundImage = highlightImage
            guard let highlightResult = highlightBlend.outputImage else { return }
            
            // Blend de sombras
            let shadowBlendCustom = MTIBlendFilter(blendMode: .normal)
            shadowBlendCustom.inputImage = shadowFinal
            shadowBlendCustom.inputBackgroundImage = highlightResult
            shadowBlendCustom.intensity = state.duotoneShadowIntensity
            guard let shadowBlended = shadowBlendCustom.outputImage else { return }
            // Blend de destaques
            let highlightBlendCustom = MTIBlendFilter(blendMode: .normal)
            highlightBlendCustom.inputImage = highlightResult
            highlightBlendCustom.inputBackgroundImage = shadowFinal
            highlightBlendCustom.intensity = state.duotoneHighlightIntensity
            guard let highlightBlended = highlightBlendCustom.outputImage else { return }
            // Combina os dois resultados (média)
            let combineBlend = MTIBlendFilter(blendMode: .normal)
            combineBlend.inputImage = shadowBlended
            combineBlend.inputBackgroundImage = highlightBlended
            combineBlend.intensity = 0.5
            guard let balancedResult = combineBlend.outputImage else { return }
            // Segundo blend para criar o efeito final com overlay
            let finalBlend = MTIBlendFilter(blendMode: .overlay)
            finalBlend.inputImage = balancedResult
            finalBlend.inputBackgroundImage = highlightResult
            guard let duotoneOutput = finalBlend.outputImage else { return }
            // Removido: blend final com duotoneIntensity
            duotoneImage = duotoneOutput
        } else {
            duotoneImage = tintedImage
        }

        // Filtro de inversão de cores (quando colorInvert > 0)
        let finalImage: MTIImage
        if state.colorInvert > 0.0 {
            let invertFilter = MTIColorInvertFilter()
            invertFilter.inputImage = duotoneImage
            guard let invertedImage = invertFilter.outputImage else { return }
            // Se colorInvert < 1.0, fazemos um blend entre a imagem original e a invertida
            if state.colorInvert < 1.0 {
                let blendFilter = MTIBlendFilter(blendMode: .normal)
                blendFilter.inputImage = invertedImage
                blendFilter.inputBackgroundImage = duotoneImage
                blendFilter.intensity = state.colorInvert
                guard let blendedImage = blendFilter.outputImage else { return }
                finalImage = blendedImage
            } else {
                finalImage = invertedImage
            }
        } else {
            finalImage = duotoneImage
        }
        
        // Aplicar efeito de duotone se habilitado
        if state.duotoneEnabled {
            do {
                let cgimg = try mtiContext.makeCGImage(from: finalImage)
                let uiImage = UIImage(cgImage: cgimg)
                DispatchQueue.main.async {
                    self.previewImage = uiImage
                }
                os_log("[PhotoEditorViewModel] Duotone image generated successfully.")
            } catch {
                os_log("[PhotoEditorViewModel] Failed to generate duotone image: %{public}@", String(describing: error))
            }
        } else {
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
}
