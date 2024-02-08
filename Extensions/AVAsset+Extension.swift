//
//  AVAsset+Extension.swift
//
//
//  Created by Roman Rakhlin on 2/6/24.
//

import AVFoundation
import AudioToolbox
import VideoToolbox
import UIKit

// MARK: - Video Size

public extension AVAsset {
    private var videoTrack: AVAssetTrack? {
        return tracks(withMediaType: .video).first
    }
    
    var videoSize: CGSize {
        return videoTrack?.videoSize ?? .zero
    }
}
