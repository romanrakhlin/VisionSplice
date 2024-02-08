//
//  File.swift
//  
//
//  Created by Roman Rakhlin on 2/8/24.
//

import AVFoundation
import UIKit

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func resized(toFit boxSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = self.scale
        let box = CGRect(origin: .zero, size: boxSize)
        let fittingRect = AVMakeRect(aspectRatio: self.size, insideRect: box)
        let renderer = UIGraphicsImageRenderer(size: fittingRect.size, format: format)
        
        return renderer.image { ctx in
            self.draw(in: CGRect(origin: .zero, size: fittingRect.size))
        }
    }
    
    func resized(toFill boxSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = self.scale
        let imageRect = CGRect(origin: .zero, size: self.size)
        let roi = AVMakeRect(aspectRatio: boxSize, insideRect: imageRect)
        let renderer = UIGraphicsImageRenderer(size: roi.size, format: format)
        
        return renderer.image { ctx in
            let offsetOrigin = CGPoint(
                x: -roi.origin.x,
                y: -roi.origin.y)
            self.draw(at: offsetOrigin)
        }
    }
}
