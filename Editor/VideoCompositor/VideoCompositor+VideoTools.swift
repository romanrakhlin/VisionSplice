//
//  VideoCompositor+VideoTools.swift
//
//
//  Created by Roman Rakhlin on 2/8/24.
//

import AVFoundation
import UIKit

// MARK: - Generate from image
extension VideoCompositor {
    static func makeStillVideo(
        fromImage image: UIImage,
        duration: TimeInterval,
        renderSize: CGSize,
        fps: Int32,
        bitrate: Float,
        storeDirectory: URL,
        fileName: String = UUID().uuidString
    ) async throws -> URL {
        guard let buffer = image.pixelBuffer() else {
            throw VideoCompositor.Error.pixelBufferCreationFailed
        }
        return try await makeStillVideo(
            fromImage: buffer,
            duration: duration,
            renderSize: renderSize,
            fps: fps,
            bitrate: bitrate,
            storeDirectory: storeDirectory,
            outputName: fileName)
    }
    
    static func makeStillVideo(
        fromImage buffer: CVPixelBuffer,
        duration: TimeInterval,
        renderSize: CGSize,
        fps: Int32,
        bitrate: Float,
        storeDirectory: URL,
        outputName: String
    ) async throws -> URL {
        let outputVideoFileURL = URL(fileURLWithPath: storeDirectory.path)
            .appendingPathComponent(outputName)
            .appendingPathExtension("mp4")
        FileManager.default.deleteIfExists(at: outputVideoFileURL)

        // create an assetwriter instance
        let assetWriter = try AVAssetWriter(outputURL: outputVideoFileURL, fileType: .mp4)

        let compressionSettings: [String: Any] = [
            AVVideoAverageBitRateKey: bitrate,
            AVVideoAllowFrameReorderingKey: false,
            AVVideoExpectedSourceFrameRateKey: fps,
        ]

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(renderSize.width),
            AVVideoHeightKey: Int(renderSize.height),
            AVVideoCompressionPropertiesKey: compressionSettings,
        ]

        // create a single video input
        let assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        // create an adaptor for the pixel buffer
        let assetWriterAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: assetWriterInput,
            sourcePixelBufferAttributes: nil
        )
        // add the input to the asset writer
        assetWriter.add(assetWriterInput)

        // begin the session
        assetWriter.startWriting()

        var currentFrame: Int64 = 0
        let endFrame = Int64(duration * Double(fps))
        assetWriter.startSession(atSourceTime: .zero)
        while currentFrame < endFrame {
            if assetWriterInput.isReadyForMoreMediaData {
                let frameTime = CMTimeMake(value: currentFrame, timescale: fps)
                // append the contents of the pixelBuffer at the correct time
                assetWriterAdaptor.append(buffer, withPresentationTime: frameTime)
                currentFrame += 1
            }
        }
        let endTime = CMTimeMake(value: endFrame, timescale: fps)
        assetWriter.endSession(atSourceTime: endTime)

        // close everything
        assetWriterInput.markAsFinished()
        await assetWriter.finishWriting()
        if let error = assetWriter.error {
            throw error
        }
        return outputVideoFileURL
    }
}

// MARK: - Merge chunks

extension VideoCompositor {
    static func mergeVideosComposition(_ urls: [URL]) async throws -> AVMutableComposition {
        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )!
        
        let assets = urls.map { AVURLAsset(url: $0) }
        let tracksToMerge = assets.compactMap { $0.tracks(withMediaType: .video).first }
        guard !tracksToMerge.isEmpty else {
            throw Error.noVideoTracksFound
        }
        
        var chunkStart = CMTime.zero
        
        for idx in 0 ..< tracksToMerge.count {
            try! videoTrack.insertTimeRange(
                tracksToMerge[idx].timeRange,
                of: tracksToMerge[idx],
                at: chunkStart
            )
            let chunkDuration = tracksToMerge[idx].timeRange.duration
            chunkStart = CMTimeAdd(chunkStart, chunkDuration)
        }
        
        return composition
    }
    
    static func mergeVideos(
        _ urls: [URL],
        storeDirectory: URL,
        outputName: String
    ) async throws -> URL {
        let composition = try await mergeVideosComposition(urls)

        let (exportSession, outputVideoFileURL) = prepareDefaultExportSessionAndFileURL(
            asset: composition,
            storeDirectory: storeDirectory,
            fileName: outputName
        )
        await exportSession.export()
        if let error = exportSession.error {
            throw error
        }
        return outputVideoFileURL
    }
    
}

// MARK: - Frames

extension VideoCompositor {
    static func exportFirstFrame(from video: AVAsset) throws -> CVPixelBuffer {
        try exportFrame(from: video, at: .zero)
    }

    static func exportLastFrame(from video: AVAsset) throws -> CVPixelBuffer {
        let duration = video.duration
        let time = CMTime(seconds: duration.seconds)

        return try exportFrame(from: video, at: time)
    }

    static func exportFrame(from video: AVAsset, at time: CMTime) throws -> CVPixelBuffer {
        let assetImageGenerator = AVAssetImageGenerator(asset: video)

        let lastFrame = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
        guard let buffer = lastFrame.pixelBuffer(
            width: lastFrame.width,
            height: lastFrame.height,
            orientation: .up
        ) else {
            throw Error.pixelBufferCreationFailed
        }

        return buffer
    }
}
