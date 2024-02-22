//
//  VideoEditor+Thumbnail.swift
//  
//
//  Created by Roman Rakhlin on 2/22/24.
//

import UIKit
import AVFoundation

extension VideoEditor {
    static func generateThumbnail(from asset: AVAsset, at time: CMTime = CMTime(seconds: 0.0)) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            generateThumbnail(from: asset, at: time) { result in
                continuation.resume(with: result)
            }
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
}
