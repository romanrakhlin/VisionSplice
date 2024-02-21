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

extension AVAsset {
    private var videoTrack: AVAssetTrack? {
        return tracks(withMediaType: .video).first
    }
    
    var videoSize: CGSize {
        return videoTrack?.videoSize ?? .zero
    }
}

// MARK: - Formats

extension AVAsset {
    var formattedDuration: String {
        let durationInSeconds = self.duration.seconds
        let minutes = Int(durationInSeconds / 60)
        let seconds = Int(durationInSeconds.truncatingRemainder(dividingBy: 60))
            
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
