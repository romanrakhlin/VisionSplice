//
//  VideoEditor+Resize.swift
//
//
//  Created by Roman Rakhlin on 2/8/24.
//

import AVFoundation

extension VideoEditor {
    enum ResizeError: Swift.Error {
        case missingVideoTrack
        case exportSessionInitializationFailed
        case failedScale
    }
    
    public static func export(videoAsset: AVAsset, outputURL: URL, framesPerSecond: Int32, targetSize: CGSize? = nil) async throws {
        let videoTracks: [AVAssetTrack]
        if #available(iOS 15.0, *) {
            videoTracks = try await videoAsset.loadTracks(withMediaType: .video)
        } else {
            videoTracks = videoAsset.tracks(withMediaType: .video)
        }
        
        guard let videoTrack = videoTracks.first else {
            throw ResizeError.missingVideoTrack
        }
        
        let resizeComposition = videoComposition(for: videoTrack, aspectFillSize: targetSize, framesPerSecond: framesPerSecond)
        
        guard let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality) else {
            throw ResizeError.exportSessionInitializationFailed
        }
        
        exportSession.videoComposition = resizeComposition
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        
        await exportSession.export()
    }
    
    public static func videoComposition(for videoTrack: AVAssetTrack, aspectFillSize: CGSize?, framesPerSecond: Int32, timeRange: CMTimeRange? = nil) -> AVVideoComposition {
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
    
    public static func crop(videoAsset: AVAsset, with cropRect: CGRect, outputURL: URL) async throws {
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

extension AVAssetTrack {
    var fixedPreferredTransform: CGAffineTransform {
        var t = preferredTransform
        
        switch(t.a, t.b, t.c, t.d) {
        case (1, 0, 0, 1):
            t.tx = 0
            t.ty = 0
        case (1, 0, 0, -1):
            t.tx = 0
            t.ty = naturalSize.height
        case (-1, 0, 0, 1):
            t.tx = naturalSize.width
            t.ty = 0
        case (-1, 0, 0, -1):
            t.tx = naturalSize.width
            t.ty = naturalSize.height
        case (0, -1, 1, 0):
            t.tx = 0
            t.ty = naturalSize.width
        case (0, 1, -1, 0):
            t.tx = naturalSize.height
            t.ty = 0
        case (0, 1, 1, 0):
            t.tx = 0
            t.ty = 0
        case (0, -1, -1, 0):
            t.tx = naturalSize.height
            t.ty = naturalSize.width
        default:
            break
        }
        
        return t
    }
}
