//
//  FrameItem.swift
//
//
//  Created by Roman Rakhlin on 2/6/24.
//

import AVFoundation
import CoreMedia
import UIKit

enum FrameItemConfiguration {
    static let thumbnailSize = CGSize(width: 256, height: 512)
}

protocol FrameItem: AnyObject, Identifiable {
    var id: UUID { get }
    var duration: CMTime { get }
    func generateAsset(config: VideoConfigiration) async throws -> AVAsset
    func generateThumbnail() async throws -> UIImage
}
