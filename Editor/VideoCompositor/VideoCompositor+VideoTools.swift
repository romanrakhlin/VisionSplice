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
        // Cretae output URL
        let outputVideoFileURL = URL(fileURLWithPath: storeDirectory.path)
            .appendingPathComponent(outputName)
            .appendingPathExtension("mp4")
        FileManager.default.deleteIfExists(at: outputVideoFileURL)

        // Create an AssetWriter
        let assetWriter = try AVAssetWriter(outputURL: outputVideoFileURL, fileType: .mp4)
        
        // Settings for video & audio
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(renderSize.width),
            AVVideoHeightKey: Int(renderSize.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: bitrate,
                AVVideoAllowFrameReorderingKey: false,
                AVVideoExpectedSourceFrameRateKey: fps,
            ],
        ]
        
        let audioBitRate = 192000
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100.0,
            AVEncoderBitRateKey: audioBitRate
        ]

        // Create a single video input
        let videoAssetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let audioAssetWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        
        // Create an adaptor for the pixel buffer
        let assetWriterAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoAssetWriterInput,
            sourcePixelBufferAttributes: nil
        )
        
        // Add the input to the asset writer
        assetWriter.add(videoAssetWriterInput)
        assetWriter.add(audioAssetWriterInput)

        // Begin the session
        assetWriter.startWriting()

        var currentFrame: Int64 = 0
        let framesCount = Int64(duration * Double(fps))
        
        assetWriter.startSession(atSourceTime: .zero)
        
        // Add audio
        if let audio = createSilentAudio(startFrame: currentFrame, framesCount: framesCount, sampleRate: Float64(audioBitRate)) {
            audioAssetWriterInput.append(audio)
        }
        
        while currentFrame < framesCount {
            if videoAssetWriterInput.isReadyForMoreMediaData {
                let frameTime = CMTimeMake(value: currentFrame, timescale: fps)
                
                // Append the contents of the pixelBuffer at the correct time
                assetWriterAdaptor.append(buffer, withPresentationTime: frameTime)
                currentFrame += 1
            }
        }
        
        let endTime = CMTimeMake(value: framesCount, timescale: fps)
        assetWriter.endSession(atSourceTime: endTime)

        // Close everything
        videoAssetWriterInput.markAsFinished()
        audioAssetWriterInput.markAsFinished()
        await assetWriter.finishWriting()
        
        if let error = assetWriter.error { throw error }
        
        return outputVideoFileURL
    }
    
    static private func createSilentAudio(startFrame: Int64, framesCount: Int64, sampleRate: Float64) -> CMSampleBuffer? {
        let channelsAmount: UInt32 = 1
        let bytesPerFrame = UInt32(2 * channelsAmount)
        let blockSize = Int(framesCount) * Int(bytesPerFrame)
        
        var block: CMBlockBuffer?
        
        var status = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nil,
            blockLength: blockSize,
            blockAllocator: nil,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: blockSize,
            flags: 0,
            blockBufferOut: &block
        )
        assert(status == kCMBlockBufferNoErr)
        
        guard var eBlock = block else { return nil }
        
        status = CMBlockBufferFillDataBytes(with: 0, blockBuffer: eBlock, offsetIntoDestination: 0, dataLength: blockSize)
        assert(status == kCMBlockBufferNoErr)
        
        var asbd = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kLinearPCMFormatFlagIsSignedInteger,
            mBytesPerPacket: bytesPerFrame,
            mFramesPerPacket: 1,
            mBytesPerFrame: bytesPerFrame,
            mChannelsPerFrame: channelsAmount,
            mBitsPerChannel: 16,
            mReserved: 0
        )
        
        var formatDesc: CMAudioFormatDescription?
        
        status = CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: &asbd,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &formatDesc
        )
        assert(status == noErr)
        
        var sampleBuffer: CMSampleBuffer?
        
        status = CMAudioSampleBufferCreateReadyWithPacketDescriptions(
            allocator: kCFAllocatorDefault,
            dataBuffer: eBlock,
            formatDescription: formatDesc!,
            sampleCount: Int(framesCount),
            presentationTimeStamp: CMTimeMake(value: startFrame, timescale: Int32(sampleRate)),
            packetDescriptions: nil,
            sampleBufferOut: &sampleBuffer
        )
        assert(status == noErr)
        
        return sampleBuffer
    }
}
