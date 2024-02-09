import Foundation
import SwiftUI
import AVFoundation

public struct CameraViewControllerRepresentable: UIViewRepresentable {
    
    @EnvironmentObject var viewModel: CameraViewModel
    
    public func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        DispatchQueue.main.async {
            if viewModel.preview == nil {
                viewModel.preview = AVCaptureVideoPreviewLayer(session: viewModel.session)
            }
            
            viewModel.preview.frame = view.frame
            viewModel.preview.videoGravity = .resizeAspectFill
            
            view.layer.addSublayer(viewModel.preview)
        }
        
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {}
}
