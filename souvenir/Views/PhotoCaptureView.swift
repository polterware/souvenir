import SwiftUI
import AVFoundation

struct PhotoCaptureView: View {
    var onPhotoCaptured: (UIImage) -> Void
    @State private var capturedImage: UIImage? = nil
    @State private var isPhotoTaken: Bool = false
    @State private var isFlashOn: Bool = false
    @State private var isGridOn: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            CameraPreview(capturedImage: $capturedImage, isPhotoTaken: $isPhotoTaken, isFlashOn: $isFlashOn)
                .frame(
                    width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.width * 16.0 / 9.0
                )
                .background(.red)
                .cornerRadius(20)
            
            if isGridOn {
                GeometryReader { geo in
                    Path { path in
                        let width = geo.size.width
                        let height = geo.size.height
                        let columnWidth = width / 3
                        let rowHeight = height / 3
                        path.move(to: CGPoint(x: columnWidth, y: 0))
                        path.addLine(to: CGPoint(x: columnWidth, y: height))
                        path.move(to: CGPoint(x: 2 * columnWidth, y: 0))
                        path.addLine(to: CGPoint(x: 2 * columnWidth, y: height))
                        path.move(to: CGPoint(x: 0, y: rowHeight))
                        path.addLine(to: CGPoint(x: width, y: rowHeight))
                        path.move(to: CGPoint(x: 0, y: 2 * rowHeight))
                        path.addLine(to: CGPoint(x: width, y: 2 * rowHeight))
                    }
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                }
            }
            
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                        }
                        .modifier(BoxBlankStyle(cornerRadius: .infinity))
                    }
                    
                    
                    Spacer()
                    
                    Button(action: {
                        isFlashOn.toggle()
                    }) {
                        HStack {
                            Image(systemName: isFlashOn ? "bolt.fill" : "bolt")
                        }
                        .modifier(BoxBlankStyle(cornerRadius: .infinity))
                    }
                
                }
                Spacer()
                HStack (alignment: .center){
                    
                    Spacer()
                    
                    Button(action: {
                        NotificationCenter.default.post(name: .capturePhoto, object: nil)
                    }) {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(.thinMaterial, lineWidth: 2)
                            )
                            .shadow(radius: 5)
                    }
                    .padding(20)
                    
                    Spacer()
                    
                    
                }
                
            }
            .frame(
                width: UIScreen.main.bounds.width,
                height: UIScreen.main.bounds.width * 16.0 / 9.0
            )
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: capturedImage) { _, newImage in
            if let image = newImage {
                onPhotoCaptured(image)
            }
        }
        
        
        
        HStack{
            Button(action: {
                isGridOn.toggle()
            }) {
                Image(systemName: isGridOn ? "square.grid.3x3.fill" : "square.grid.3x3")
                    .modifier(BoxBlankStyle(cornerRadius: .infinity))
            }
            
            Spacer()
            Button(action: {
                NotificationCenter.default.post(name: .switchCamera, object: nil)
            }) {
                Image(systemName: "camera.rotate")
                    .modifier(BoxBlankStyle(cornerRadius: .infinity))
            }
            
        }
        
        Spacer()
    }
}

struct CameraPreview: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isPhotoTaken: Bool
    @Binding var isFlashOn: Bool

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.capturedImage = $capturedImage
        controller.isPhotoTaken = $isPhotoTaken
        controller.isFlashOn = $isFlashOn
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var captureSession: AVCaptureSession?
    var photoOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var capturedImage: Binding<UIImage?> = .constant(nil)
    var isPhotoTaken: Binding<Bool> = .constant(false)
    var isFlashOn: Binding<Bool> = .constant(false)
    var currentCameraPosition: AVCaptureDevice.Position = .back
    var flashOverlayView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

extension Notification.Name {
    static let capturePhoto = Notification.Name("capturePhoto")
    static let switchCamera = Notification.Name("switchCamera")
}

#Preview {
    PhotoCaptureView(onPhotoCaptured: { _ in })
}
