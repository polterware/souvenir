import SwiftUI
import AVFoundation
import Foundation
// Importar os módulos recém-criados
import CameraPreview
import CameraViewController
import Notification_Camera

struct PhotoCaptureView: View {
    var onPhotoCaptured: (UIImage) -> Void
    @State private var capturedImage: UIImage? = nil
    @State private var isPhotoTaken: Bool = false
    @State private var isFlashOn: Bool = false
    @State private var isGridOn: Bool = false
    @State private var zoomFactor: CGFloat = 1.0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            ZStack {
                CameraPreview(capturedImage: $capturedImage, isPhotoTaken: $isPhotoTaken, isFlashOn: $isFlashOn, zoomFactor: $zoomFactor)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 16.0 / 9.0)
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
                        
                       
                    }
                    Spacer()
                    HStack(alignment: .center) {
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
                        // Additional button or user-selected functionality can be placed here
                    }
                }
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 16.0 / 9.0)
            }
            
            HStack(alignment: .center) {
                Button(action: {
                    isGridOn.toggle()
                }) {
                    Image(systemName: isGridOn ? "square.grid.3x3.fill" : "square.grid.3x3")
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
        .navigationBarBackButtonHidden(true)
        .onChange(of: capturedImage) { _, newImage in
            if let image = newImage {
                onPhotoCaptured(image)
            }
        }
        .padding(.top)
    }
}

#Preview {
    PhotoCaptureView(onPhotoCaptured: { _ in })
}
