//
//  VideoEditor.swift
//  
//
//  Created by Roman Rakhlin on 2/8/24.
//

import AVFoundation
import UIKit

final class VideoEditor {
    static func trimMedia(videoURL: URL, audioURL: URL? = nil, destinationURL: URL, startPoint: CMTime, endPoint: CMTime, completion: @escaping (URL?) -> Void) {
        guard videoURL.isFileURL, destinationURL.isFileURL else {
            completion(nil)
            return
        }
        
        let options = [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ]
        let videoAsset = AVURLAsset(url: videoURL, options: options)
        
        var audioAsset: AVURLAsset?
        var audioCompTrack: AVMutableCompositionTrack?
        var assetAudioTrack: AVAssetTrack?
        
        let composition = AVMutableComposition()
        
        guard let videoCompTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let assetVideoTrack: AVAssetTrack = videoAsset.tracks(withMediaType: .video).first else {
            completion(nil)
            return
        }
        
        videoCompTrack.preferredTransform = assetVideoTrack.preferredTransform
        
        if let audioURL = audioURL {
            audioAsset = AVURLAsset(url: audioURL)
            audioCompTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            assetAudioTrack = audioAsset!.tracks(withMediaType: .audio).first
        }
        
        let durationOfCurrentSlice = CMTimeSubtract(endPoint, startPoint)
        let timeRangeForCurrentSlice = CMTimeRangeMake(start: startPoint, duration: durationOfCurrentSlice)
        
        if let audioCompTrack = audioCompTrack, let assetAudioTrack = assetAudioTrack {
            do {
                try audioCompTrack.insertTimeRange(timeRangeForCurrentSlice, of: assetAudioTrack, at: .zero)
            }
            catch let compError {
                print("[Failure] VideoEditor - trimMedia: \(compError.localizedDescription)")
                completion(nil)
            }
        }
        
        do {
            try videoCompTrack.insertTimeRange(timeRangeForCurrentSlice, of: assetVideoTrack, at: .zero)
        }
        catch let compError {
            print("[Failure] VideoEditor - trimMedia: \(compError)")
            completion(nil)
        }
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil)
            return
        }
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .mp4
        
        let start = CACurrentMediaTime()
        exportSession.exportAsynchronously {
            guard case exportSession.status = AVAssetExportSession.Status.completed else {
                print("[Failure] VideoEditor - trimMedia: \(String(describing: exportSession.error))")
                completion(nil)
                assertionFailure()
                return
            }
            
            print("[Success] VideoEditor - trimMedia \(CACurrentMediaTime() - start)s")
            completion(destinationURL)
        }
    }
    
    static func mergeVideo(_ assets: [AVAsset], outputURL: URL, completion: @escaping (Error?) -> Void) {
        precondition(assets.isEmpty == false)
        
        let composition = AVMutableComposition()
        let startTimeOffset = CMTime.zero
        var frameRate: Int32 = 30
        
        do {
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
            let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
            
            try assets.forEach { asset in
                let assetDuration = asset.duration
                let trackRange = CMTimeRange(start: .zero, duration: assetDuration)
                
                if let audioTrack = asset.tracks(withMediaType: .audio).first {
                    try compositionAudioTrack.insertTimeRange(trackRange, of: audioTrack, at: startTimeOffset)
                }
                
                if let videoTrack = asset.tracks(withMediaType: .video).first {
                    try compositionVideoTrack.insertTimeRange(trackRange, of: videoTrack, at: startTimeOffset)
                }
            }
            
            frameRate = Int32(compositionVideoTrack.nominalFrameRate)
        } catch {
            completion(error)
            return
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: frameRate)
        videoComposition.renderSize = assets.first!.videoSize
        
        let exportSession = AVAssetExportSession(asset: composition,
                                                 presetName: AVAssetExportPresetPassthrough)!
        
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        
        let start = CACurrentMediaTime()
        exportSession.exportAsynchronously {
            guard exportSession.status == .completed else {
                print("[Failure] VideoEditor - mergeVideo: \(String(describing: exportSession.error))")
                completion(exportSession.error!)
                return
            }
            
            print("[Success] VideoEditor - mergeVideo \(CACurrentMediaTime() - start)s")
            completion(nil)
        }
    }
    
    static func generateThumbnail(
        from asset: AVAsset,
        at time: CMTime = CMTime(seconds: 0.0),
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.appliesPreferredTrackTransform = true
        let times = [NSValue(time: time)]
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: times) { _, cgImage, _, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let cgImage = cgImage {
                    let image = UIImage(cgImage: cgImage)
                    completion(.success(image))
                    return
                }
            }
        }
    }
    
    static func generateThumbnail(from asset: AVAsset, at time: CMTime = CMTime(seconds: 0.0)) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            generateThumbnail(from: asset, at: time) { result in
                continuation.resume(with: result)
            }
        }
    }
}
