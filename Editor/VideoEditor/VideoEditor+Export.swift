//
//  VideoEditor+Export.swift
//  
//
//  Created by Roman Rakhlin on 2/22/24.
//

import AVFoundation

extension VideoEditor {
    static func export(videoAsset: AVAsset, outputURL: URL, framesPerSecond: Int32, targetSize: CGSize? = nil) async throws {
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
}
