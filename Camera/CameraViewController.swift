import Foundation
import SwiftUI
import AVFoundation

public struct CameraViewController: UIViewRepresentable {
    
    @EnvironmentObject var camera: CameraViewModel
    
    public func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        DispatchQueue.main.async {
            if camera.preview == nil {
                camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
            }
            
            camera.preview.frame = view.frame
            camera.preview.videoGravity = .resizeAspectFill
            
            view.layer.addSublayer(camera.preview)
        }
        
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {}
}
