//
//  FrameVideoItem.swift
//
//
//  Created by Roman Rakhlin on 2/6/24.
//

import AVFoundation
import UIKit

final class FrameVideoItem: FrameItem {
    
    enum Error: Swift.Error {
        case assetGenerationFailed
        case assetGenerationInProgress
        case invalidSource
    }

    let sourceAsset: AVAsset

    var duration: CMTime
    private(set) var thumbnail: UIImage?

    private var generatedAsset: AVAsset?
    private var isGeneratingAsset: Bool = false

    init(asset: AVAsset) {
        sourceAsset = asset
        duration = asset.duration
    }

    func generateAsset(config: VideoConfigiration) async throws -> AVAsset {
        if let generatedAsset, generatedAsset.videoSize == config.videoSize {
            return generatedAsset
        }

        if isGeneratingAsset {
            throw Error.assetGenerationInProgress
        }
        isGeneratingAsset = true
        defer { isGeneratingAsset = false }

        guard let videoTrack = sourceAsset.tracks(withMediaType: .video).first else {
            throw Error.invalidSource
        }

        let resizeComposition = VideoEditor.videoComposition(
            for: videoTrack,
            aspectFillSize: config.videoSize,
            framesPerSecond: config.fps,
            timeRange: CMTimeRange(start: .zero, duration: duration)
        )

        let (exportSession, outputURL) = VideoCompositor.prepareDefaultExportSessionAndFileURL(
            asset: sourceAsset,
            quality: config.quality,
            storeDirectory: config.workingDirectoryURL,
            fileName: UUID().uuidString
        )

        exportSession.videoComposition = resizeComposition
        exportSession.timeRange = CMTimeRange(
            start: .zero,
            end: min(sourceAsset.duration, duration)
        )

        await exportSession.export()
        if let error = exportSession.error {
            throw error
        }
        let generatedAsset = AVAsset(url: outputURL)
        self.generatedAsset = generatedAsset

        return generatedAsset
    }

    func generateThumbnail() async throws -> UIImage {
        if let thumbnail {
            return thumbnail
        }

        let thumbnail: UIImage
        if let generatedAsset {
            thumbnail = try await VideoEditor.generateThumbnail(from: generatedAsset)
        } else {
            thumbnail = try await VideoEditor.generateThumbnail(
                from: sourceAsset,
                at: .zero
            )
        }
        self.thumbnail = thumbnail

        return thumbnail
    }
}

extension AVAsset {
    // TODO: - Fix video transform after adding empty time range
    func addingEmptyRange(toInclude timeRange: CMTimeRange) throws -> AVAsset {
        guard let assetVideoTrack = tracks(withMediaType: .video).first,
              assetVideoTrack.timeRange.end < timeRange.end
        else {
            return self
        }

        let composition = AVMutableComposition()
        let lastFrameDuration = CMTime(value: 1, timescale: 60)
        let lastFrameRange = CMTimeRange(start: duration - lastFrameDuration, end: duration)
        let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )!
        try videoTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: assetVideoTrack.timeRange.duration),
            of: assetVideoTrack,
            at: .zero
        )
        try videoTrack.insertTimeRange(
            lastFrameRange,
            of: assetVideoTrack,
            at: timeRange.end
        )
        videoTrack.preferredTransform = assetVideoTrack.preferredTransform
            .concatenating(videoTrack.preferredTransform)

        return composition
    }
}
