import SwiftUI
import AVFoundation

struct CameraPreview: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isPhotoTaken: Bool
    @Binding var isFlashOn: Bool
    @Binding var zoomFactor: CGFloat

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.capturedImage = $capturedImage
        controller.isPhotoTaken = $isPhotoTaken
        controller.isFlashOn = $isFlashOn
        controller.zoomFactor = $zoomFactor
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        uiViewController.updateZoomFactor()
    }
}
