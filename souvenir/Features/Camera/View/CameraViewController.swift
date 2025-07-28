import UIKit
import AVFoundation
import SwiftUI

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var captureSession: AVCaptureSession?
    var photoOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var capturedImage: Binding<UIImage?> = .constant(nil)
    var isPhotoTaken: Binding<Bool> = .constant(false)
    var isFlashOn: Binding<Bool> = .constant(false)
    var zoomFactor: Binding<CGFloat> = .constant(1.0)
    var currentCameraPosition: AVCaptureDevice.Position = .back
    var flashOverlayView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ...existing code...
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .hd1920x1080
        
        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }
        
        if captureSession?.canAddInput(videoInput) == true {
            captureSession?.addInput(videoInput)
        }
        
        photoOutput = AVCapturePhotoOutput()
        if let cs = captureSession, let po = photoOutput, cs.canAddOutput(po) {
            cs.addOutput(po)
        }
        
        if let cs = captureSession {
            previewLayer = AVCaptureVideoPreviewLayer(session: cs)
            previewLayer?.videoGravity = .resizeAspect
            previewLayer?.frame = view.layer.bounds
            if let pl = previewLayer {
                view.layer.addSublayer(pl)
            }
        }
        
        flashOverlayView = UIView(frame: view.bounds)
        flashOverlayView?.backgroundColor = UIColor.white
        flashOverlayView?.alpha = 0
        view.addSubview(flashOverlayView!)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        view.addGestureRecognizer(pinchGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        view.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(capturePhoto), name: .capturePhoto, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(switchCamera), name: .switchCamera, object: nil)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let pl = previewLayer {
            pl.frame = view.bounds
        }
        flashOverlayView?.frame = view.bounds
    }
    
    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        if isFlashOn.wrappedValue {
            settings.flashMode = .on
        } else {
            settings.flashMode = .off
        }
        guard let po = photoOutput else { return }
        po.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        
        DispatchQueue.main.async {
            // Flash animation for visual feedback
            self.flashOverlayView?.alpha = 1.0
            UIView.animate(withDuration: 0.3, animations: {
                self.flashOverlayView?.alpha = 0.0
            })
            self.capturedImage.wrappedValue = image
            self.isPhotoTaken.wrappedValue = true
        }
    }
    
    func updateZoomFactor() {
        guard let currentInput = captureSession?.inputs.first as? AVCaptureDeviceInput else { return }
        let device = currentInput.device
        do {
            try device.lockForConfiguration()
            // Clamp the zoom factor between 0.5 and 5.0, but also respect the device's maximum zoom factor
            let desiredZoom = min(max(zoomFactor.wrappedValue, 0.5), min(5.0, device.activeFormat.videoMaxZoomFactor))
            device.videoZoomFactor = desiredZoom
            device.unlockForConfiguration()
        } catch {
            print("Error setting zoom factor: \(error)")
        }
    }
    
    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard let currentInput = captureSession?.inputs.first as? AVCaptureDeviceInput else { return }
        let device = currentInput.device
        do {
            try device.lockForConfiguration()
            let maxZoom = device.activeFormat.videoMaxZoomFactor
            let desiredZoomFactor = min(max(device.videoZoomFactor * gesture.scale, 1.0), maxZoom)
            device.videoZoomFactor = desiredZoomFactor
            device.unlockForConfiguration()
            gesture.scale = 1.0
        } catch {
            print("Error setting zoom factor")
        }
    }
    
    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        guard let currentInput = captureSession?.inputs.first as? AVCaptureDeviceInput else { return }
        let device = currentInput.device
        let focusPoint = CGPoint(x: location.y / view.bounds.height, y: 1.0 - (location.x / view.bounds.width))
        
        if device.isFocusPointOfInterestSupported && device.isExposurePointOfInterestSupported {
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .autoExpose
                device.unlockForConfiguration()
            } catch {
                print("Error setting focus")
            }
            
            let focusRect = CGRect(x: location.x - 50, y: location.y - 50, width: 100, height: 100)
            let focusIndicator = UIView(frame: focusRect)
            focusIndicator.layer.borderColor = UIColor.yellow.cgColor
            focusIndicator.layer.borderWidth = 2.0
            focusIndicator.backgroundColor = UIColor.clear
            view.addSubview(focusIndicator)
            UIView.animate(withDuration: 1.0, animations: {
                focusIndicator.alpha = 0
            }) { _ in
                focusIndicator.removeFromSuperview()
            }
        }
    }
    
    @objc func switchCamera() {
        guard let currentInput = captureSession?.inputs.first as? AVCaptureDeviceInput else { return }
        captureSession?.beginConfiguration()
        captureSession?.removeInput(currentInput)
        
        currentCameraPosition = (currentCameraPosition == .back) ? .front : .back
        
        guard let cs = captureSession,
              let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
            captureSession?.addInput(currentInput)
            captureSession?.commitConfiguration()
            return
        }
        if cs.canAddInput(newInput) {
            cs.addInput(newInput)
        } else {
            cs.addInput(currentInput)
        }
        cs.commitConfiguration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
        NotificationCenter.default.removeObserver(self, name: .capturePhoto, object: nil)
        NotificationCenter.default.removeObserver(self, name: .switchCamera, object: nil)
    }
}
