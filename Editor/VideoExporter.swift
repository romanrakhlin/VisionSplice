//
//  VideoExporter.swift
//  
//
//  Created by Roman Rakhlin on 2/6/24.
//

import AVFoundation

enum VideoExporter {
    enum ReelExporterError: Error {
        case emptyReelItems
    }

    /// Exports given ReelModel to a video file.
    /// - Parameters:
    ///   - reel: ReelModel to export.
    ///   - config: Reel configuration to export with.
    /// - Returns: URL of the exported video. It's saved it the temporary folder specified
    /// in `config`, so the best practice would be to copy it to store somewhere, and delete
    /// the temporary folder after you're done.
    static func export(reel: VideoViewModel, config: VideoConfigiration = .export, filename: String = UUID().uuidString) async throws -> URL {
        let exportItems = reel.items

        guard !exportItems.isEmpty else {
            throw ReelExporterError.emptyReelItems
        }

        let composition = AVMutableComposition()

        // Setup video track
        let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )!

        for item in exportItems {
            let asset = try await item.generateAsset(config: config)
            for assetVideoTrack in try await asset.loadTracks(withMediaType: .video) {
                let videoTrackTimeRange = try await assetVideoTrack.load(.timeRange)
                let timeRange = CMTimeRange(start: .zero, end: videoTrackTimeRange.duration)
                try videoTrack.insertTimeRange(
                    timeRange,
                    of: assetVideoTrack,
                    at: composition.duration
                )
            }
        }

//        #if DEVELOPMENT
//        // Setup audio track
//        try composition.addTrack(
//            type: .audio,
//            from: AVAsset(url: reel.template.audioURL),
//            duration: videoTrack.timeRange.duration
//        )
//        #endif

        let (exportSession, outputVideoFileURL) = VideoCompositor
            .prepareDefaultExportSessionAndFileURL(
                asset: composition,
                quality: config.quality,
                storeDirectory: config.exportDirectoryURL,
                fileName: filename
            )

        await exportSession.export()
        if let error = exportSession.error {
            throw error
        }
        return outputVideoFileURL
    }
}
