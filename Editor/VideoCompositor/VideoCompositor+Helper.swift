//
//  VideoCompositor+Helper.swift
//  
//
//  Created by Roman Rakhlin on 2/8/24.
//

import AVFoundation

extension VideoCompositor {
    static func prepareDefaultExportSessionAndFileURL(
        asset: AVAsset,
        quality: VideoQuality = .highest,
        storeDirectory: URL,
        fileName: String
    ) -> (AVAssetExportSession, URL) {
        let outputVideoFileURL = storeDirectory
            .appendingPathComponent(fileName)
            .appendingPathExtension("mp4")
        FileManager.default.deleteIfExists(at: outputVideoFileURL)

        let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: quality.presetName
        )!
        exportSession.outputURL = outputVideoFileURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        return (exportSession, outputVideoFileURL)
    }
}
