//
//  VideoEditor+Resize.swift
//
//
//  Created by Roman Rakhlin on 2/8/24.
//

import AVFoundation

extension VideoEditor {
    static func videoComposition(for videoTrack: AVAssetTrack, aspectFillSize: CGSize?, framesPerSecond: Int32, timeRange: CMTimeRange? = nil) -> AVVideoComposition {
        let sourceSize = videoTrack.videoSize
        let renderSize = aspectFillSize ?? sourceSize
        
        let transformLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let sourceRect = CGRect(origin: .zero, size: sourceSize)
        let aspectFillRect = AVMakeRect(aspectRatio: renderSize, insideRect: sourceRect)
        
        let scale = renderSize.width / aspectFillRect.width
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        let translation = aspectFillRect.origin.applying(scaleTransform)
        let translationTransform = CGAffineTransform(translationX: -translation.x, y: -translation.y)
        let aspectFillTransform = scaleTransform.concatenating(translationTransform)
        
        let transform = videoTrack.fixedPreferredTransform.concatenating(aspectFillTransform)
        
        transformLayerInstruction.setTransform(transform, at: .zero)
        
        let transformInstruction = AVMutableVideoCompositionInstruction()
        transformInstruction.timeRange = timeRange ?? videoTrack.timeRange
        transformInstruction.layerInstructions = [transformLayerInstruction]
        
        let composition = AVMutableVideoComposition()
        composition.instructions = [transformInstruction]
        composition.renderSize = renderSize
        composition.frameDuration = CMTimeMake(value: 1, timescale: framesPerSecond)
        
        return composition
    }
    
    static func crop(videoAsset: AVAsset, with cropRect: CGRect, outputURL: URL) async throws {
        let videoTracks: [AVAssetTrack]
        if #available(iOS 15.0, *) {
            videoTracks = try await videoAsset.loadTracks(withMediaType: .video)
        } else {
            videoTracks = videoAsset.tracks(withMediaType: .video)
        }
        
        guard let videoTrack = videoTracks.first else {
            throw ResizeError.missingVideoTrack
        }
        
        let transformLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        
        let translationTransform = CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y)
        let preferredTransform = videoTrack.preferredTransform
        let transform = preferredTransform.concatenating(translationTransform)
        
        transformLayerInstruction.setTransform(transform, at: .zero)
        
        let transformInstruction = AVMutableVideoCompositionInstruction()
        transformInstruction.timeRange = videoTrack.timeRange
        transformInstruction.layerInstructions = [transformLayerInstruction]
        
        let transformIsIdentical = preferredTransform.isIdentity
        let renderSize = CGSize(
            width: transformIsIdentical ? cropRect.width : cropRect.height,
            height: transformIsIdentical ? cropRect.height : cropRect.width
        )
        
        let cropComposition = AVMutableVideoComposition()
        cropComposition.renderSize = renderSize
        cropComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        cropComposition.instructions = [transformInstruction]
        
        guard let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality) else {
            throw ResizeError.exportSessionInitializationFailed
        }
        
        exportSession.videoComposition = cropComposition
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        
        await exportSession.export()
    }
}
