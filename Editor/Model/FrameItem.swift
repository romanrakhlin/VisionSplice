//
//  FrameItem.swift
//
//
//  Created by Roman Rakhlin on 2/6/24.
//

import UIKit
import AVFoundation

protocol FrameItem: AnyObject, Identifiable {
    var id: UUID { get }
    var duration: CMTime { get }
    func generateAsset(config: VideoConfigiration) async throws -> AVAsset
    func generateThumbnail() async throws -> UIImage
}
