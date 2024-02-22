//
//  CameraViewControllerRepresentable.swift
//
//
//  Created by Roman Rakhlin on 2/8/24.
//

import Foundation
import SwiftUI
import AVFoundation

public struct CameraViewControllerRepresentable: UIViewRepresentable {
    
    @EnvironmentObject var viewModel: CameraViewModel
    
    class LayerView: UIView {
        var parent: CameraViewControllerRepresentable!
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.sublayers?.forEach({ layer in
                layer.frame = UIScreen.main.bounds
            })
            
            if let interfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation {
                parent.viewModel.orientation = parent.orientationFrom(interfaceOrientation: interfaceOrientation)
            }
            
            CATransaction.commit()
        }
    }
    
    public func makeUIView(context: Context) -> UIView {
        let view = LayerView()
        view.parent = self
        
        if viewModel.preview == nil {
            viewModel.preview = AVCaptureVideoPreviewLayer(session: viewModel.session)
            
            Task(priority: .background) {
                if let interfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation {
                    viewModel.orientation = orientationFrom(interfaceOrientation: interfaceOrientation)
                }
            }
        }
        
        viewModel.preview.videoGravity = .resizeAspectFill
        viewModel.preview.frame = view.frame
        
        view.layer.addSublayer(viewModel.preview)
        
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {}
    
    private func orientationFrom(interfaceOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        let orientation: AVCaptureVideoOrientation
        
        switch interfaceOrientation {
        case .unknown:
            orientation = .portrait
        case .portrait:
            orientation = .portrait
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        case .landscapeLeft:
            orientation = .landscapeLeft
        case .landscapeRight:
            orientation = .landscapeRight
        @unknown default:
            orientation = .portrait
        }
        
        return orientation
    }
}
