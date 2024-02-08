//
//  AVAssetTrack.swift
//
//
//  Created by Roman Rakhlin on 2/8/24.
//

import AVFoundation

extension AVAssetTrack {
    var videoSize: CGSize {
        let trackSize = naturalSize.applying(preferredTransform)
        return .init(width: abs(trackSize.width), height: abs(trackSize.height))
    }
}
