import UIKit
import os.log

extension UIImage {
    func fixOrientation() -> UIImage {
        // Se já estiver na orientação correta, apenas retorna a imagem
        if imageOrientation == .up {
            return self
        }
        
        os_log("[fixOrientation] Corrigindo orientação da imagem: %{public}@", String(describing: self.imageOrientation))
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi/2)
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -CGFloat.pi/2)
            
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        default:
            break
        }
        
        // Cria o contexto de renderização
        guard let cgImage = self.cgImage,
              let colorSpace = cgImage.colorSpace else {
            return self
        }
        
        let bitmapInfo = cgImage.bitmapInfo
        let context = CGContext(data: nil,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: cgImage.bitsPerComponent,
                                bytesPerRow: 0,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue)
        
        guard let ctx = context else {
            return self
        }
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        guard let newCGImage = ctx.makeImage() else {
            return self
        }
        
        // Preserva a escala original da imagem
        let image = UIImage(cgImage: newCGImage, scale: self.scale, orientation: .up)
        os_log("[fixOrientation] Orientação corrigida com sucesso")
        return image
    }
    
    func resizeToFit(maxSize: CGFloat) -> UIImage? {
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
        }
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        // Always return a MetalPetal-safe image
        return resized?.withAlpha()
    }
    
    func withAlpha() -> UIImage? {
        guard let cgImage = self.cgImage else { 
            os_log("[withAlpha] No CGImage found.")
            return nil 
        }
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        // Log input info
        let alphaInfo = cgImage.alphaInfo
        let bitsPerPixel = cgImage.bitsPerPixel
        let bytesPerRow = cgImage.bytesPerRow
        os_log("[withAlpha] Input alphaInfo: %{public}@, bitsPerPixel: %d, bytesPerRow: %d", String(describing: alphaInfo), bitsPerPixel, bytesPerRow)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { 
            os_log("[withAlpha] Failed to create CGContext.")
            return nil 
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let newCGImage = context.makeImage() else { 
            os_log("[withAlpha] Failed to make new CGImage.")
            return nil 
        }
        // Log output info
        let outAlphaInfo = newCGImage.alphaInfo
        let outBitsPerPixel = newCGImage.bitsPerPixel
        let outBytesPerRow = newCGImage.bytesPerRow
        os_log("[withAlpha] Output alphaInfo: %{public}@, bitsPerPixel: %d, bytesPerRow: %d", String(describing: outAlphaInfo), outBitsPerPixel, outBytesPerRow)
        // Assert output is RGBA8888, premultiplied alpha
        if !(outAlphaInfo == .premultipliedLast || outAlphaInfo == .premultipliedFirst) {
            os_log("[withAlpha] Output image is not premultiplied alpha! Returning nil.")
            return nil
        }
        if outBitsPerPixel != 32 {
            os_log("[withAlpha] Output image is not 32bpp RGBA! Returning nil.")
            return nil
        }
        if alphaInfo != .premultipliedLast && alphaInfo != .premultipliedFirst {
            os_log("[withAlpha] Input was not premultiplied alpha, conversion performed.")
        }
        // Preserva a escala original da imagem
        return UIImage(cgImage: newCGImage, scale: self.scale, orientation: .up)
    }
}
