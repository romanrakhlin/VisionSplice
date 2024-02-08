//
//  FrameEmptyItem.swift
//
//
//  Created by Roman Rakhlin on 2/6/24.
//

import AVFoundation
import UIKit

final class FrameEmptyItem: FrameItem {
    private static let imageItem = FrameImageItem(image: emptyImage)

    var duration: CMTime { imageItem.duration }

    private let imageItem: FrameImageItem

    init() {
        imageItem = Self.imageItem
    }

    private init(imageItem: FrameImageItem) {
        self.imageItem = imageItem
    }

    func generateAsset(config: VideoConfigiration) async throws -> AVAsset {
        let composition = AVMutableComposition()

        let emptyImageAsset = try await Self.emptyImageItem.generateAsset(config: config)

        try await composition.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: emptyImageAsset,
            at: .zero
        )

        return composition
    }

    func generateThumbnail() async throws -> UIImage {
        try await imageItem.generateThumbnail()
    }
}

private extension FrameEmptyItem {
    static let emptyImage = UIGraphicsImageRenderer(size: VideoConfigiration.export.videoSize)
        .image { _ in
            UIColor.black.setFill()
        }

    static var emptyImageItem = FrameImageItem(image: emptyImage)
}
