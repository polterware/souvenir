import SwiftUI
import AVFoundation

struct PhotoCaptureView: View {
    var onPhotoCaptured: (UIImage) -> Void
    @State private var capturedImage: UIImage? = nil
    @State private var isPhotoTaken: Bool = false

    var body: some View {
        ZStack {
            CameraPreview(capturedImage: $capturedImage, isPhotoTaken: $isPhotoTaken)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                Button(action: {
                    NotificationCenter.default.post(name: .capturePhoto, object: nil)
                }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.gray, lineWidth: 2)
                        )
                        .shadow(radius: 5)
                }
                .padding(.bottom, 30)
            }
        }
        .onChange(of: capturedImage) { newImage in
            if let image = newImage {
                onPhotoCaptured(image)
            }
        }
    }
}

struct CameraPreview: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isPhotoTaken: Bool

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.capturedImage = $capturedImage
        controller.isPhotoTaken = $isPhotoTaken
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var capturedImage: Binding<UIImage?>!
    var isPhotoTaken: Binding<Bool>!

    override func viewDidLoad() {
        super.viewDidLoad()

        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()

        NotificationCenter.default.addObserver(self, selector: #selector(capturePhoto), name: .capturePhoto, object: nil)
    }

    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }

        DispatchQueue.main.async {
            self.capturedImage.wrappedValue = image
            self.isPhotoTaken.wrappedValue = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
        NotificationCenter.default.removeObserver(self, name: .capturePhoto, object: nil)
    }
}

extension Notification.Name {
    static let capturePhoto = Notification.Name("capturePhoto")
}
