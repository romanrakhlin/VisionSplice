//
//  VideoCompositor+VideoTools.swift
//
//
//  Created by Roman Rakhlin on 2/8/24.
//

import AVFoundation
import UIKit

// MARK: - Generate Video from Image

extension VideoCompositor {
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

        // Create an assetwriter instance
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

        // Create a single video input
        let assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        
        // Create an adaptor for the pixel buffer
        let assetWriterAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: assetWriterInput,
            sourcePixelBufferAttributes: nil
        )
        
        // Add the input to the asset writer
        assetWriter.add(assetWriterInput)

        // Begin the session
        assetWriter.startWriting()

        var currentFrame: Int64 = 0
        let endFrame = Int64(duration * Double(fps))
        assetWriter.startSession(atSourceTime: .zero)
        
        while currentFrame < endFrame {
            if assetWriterInput.isReadyForMoreMediaData {
                let frameTime = CMTimeMake(value: currentFrame, timescale: fps)
                
                // Append the contents of the pixelBuffer at the correct time
                assetWriterAdaptor.append(buffer, withPresentationTime: frameTime)
                currentFrame += 1
            }
        }
        
        let endTime = CMTimeMake(value: endFrame, timescale: fps)
        assetWriter.endSession(atSourceTime: endTime)

        // Close everything
        assetWriterInput.markAsFinished()
        await assetWriter.finishWriting()
        
        if let error = assetWriter.error { throw error }
        
        return outputVideoFileURL
    }
}
