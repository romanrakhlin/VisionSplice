//
//  AVMutableComposition+Extension.swift
//  
//
//  Created by Roman Rakhlin on 2/8/24.
//

import AVFoundation

public extension AVMutableComposition {
    @discardableResult
    func addTrack(type: AVMediaType, from asset: AVAsset, start: CMTime = .zero, duration: CMTime) throws -> AVMutableCompositionTrack {

        guard let assetTrack = asset.tracks(withMediaType: type).first else {
            preconditionFailure("No audio tracks found!")
        }

        guard let compositionTrack = self.addMutableTrack(withMediaType: type,
                                                    preferredTrackID: kCMPersistentTrackID_Invalid) else {
            preconditionFailure("Failed to add audio track to composition")
        }

        var durationLeft = duration
        var startOffset: CMTime = start
        while durationLeft > .zero {
            var chunkDuration = assetTrack.timeRange.duration
            if durationLeft - chunkDuration < .zero {
                chunkDuration = durationLeft
            }

            let timeRange = CMTimeRange(start: .zero, duration: chunkDuration)

            try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: startOffset)

            durationLeft = durationLeft - chunkDuration
            startOffset = startOffset + chunkDuration
        }

        return compositionTrack
    }
}

extension AVMutableComposition {
    convenience init(
        with asset: AVAsset,
        trackTypes: [AVMediaType] = [.video, .audio]
    ) throws {
        self.init()
        for type in trackTypes {
            try addTracks(type, from: asset)
        }
    }

    public func addTracks(_ type: AVMediaType, from asset: AVAsset, trim: CMTimeRange? = nil) throws {
        let assetTracks = asset.tracks(withMediaType: type)

        guard !assetTracks.isEmpty else {
            return
        }

        guard let compositionTrack = addMutableTrack(
            withMediaType: type,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            fatalError("Failed to add composition track of type: \(type)")
        }

        for assetTrack in assetTracks {
            let trackRange = assetTrack.timeRange
            var timeRange = trim ?? trackRange
            timeRange = CMTimeRange(
                start: max(timeRange.start, trackRange.start),
                end: min(timeRange.end, trackRange.end))
            
            try compositionTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: timeRange.duration),
                of: assetTrack,
                at: timeRange.start
            )
            compositionTrack.preferredTransform = assetTrack.preferredTransform
        }
    }
}
