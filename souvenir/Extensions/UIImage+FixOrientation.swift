import UIKit
import os.log

extension UIImage {
    func fixOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? self
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
        return UIImage(cgImage: newCGImage)
    }
}
