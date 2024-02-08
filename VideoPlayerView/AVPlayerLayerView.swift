//
//  AVPlayerLayerView.swift
//  SwiftStudentChallenge2024
//
//  Created by Roman Rakhlin on 2/5/24.
//

import UIKit
import AVFoundation

public final class AVPlayerLayerView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var avPlayerLayer: AVPlayerLayer? {
        return layer as? AVPlayerLayer
    }
}
