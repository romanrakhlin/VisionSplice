//
//  FrameImageItem.swift
//
//
//  Created by Roman Rakhlin on 2/6/24.
//

import AVFoundation
import UIKit

class FrameImageItem: FrameItem {
    
    private enum Error: Swift.Error {
        case failedToCreatePixelBuffer
    }

    let image: UIImage
    let duration: CMTime = CMTime(seconds: 2.0)
    var sourceImage: UIImage

    private(set) var thumbnail: UIImage?

    private var generatedAsset: AVAsset?

    init(image: UIImage) {
        self.image = image
        sourceImage = image
    }

    func generateAsset(config: VideoConfigiration) async throws -> AVAsset {
        if let generatedAsset, generatedAsset.videoSize == config.videoSize {
            return generatedAsset
        }

        guard let pixelBuffer = image.resized(toFill: config.videoSize).pixelBuffer() else {
            throw Error.failedToCreatePixelBuffer
        }

        let url = try await VideoCompositor.makeStillVideo(
            fromImage: pixelBuffer,
            duration: duration.seconds,
            renderSize: config.videoSize,
            fps: config.fps,
            bitrate: config.bitrate,
            storeDirectory: config.workingDirectoryURL,
            outputName: UUID().uuidString
        )

        let urlAsset = AVURLAsset(url: url)
        generatedAsset = urlAsset

        return urlAsset
    }

    func generateThumbnail() async throws -> UIImage {
        if let thumbnail {
            return thumbnail
        }

        let thumbnail = image.resized(toFit: FrameItemConfiguration.thumbnailSize)
        self.thumbnail = thumbnail

        return thumbnail
    }
}
