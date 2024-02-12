//
//  VideoModel.swift
//
//
//  Created by Roman Rakhlin on 2/6/24.
//

import AVFoundation
import Combine
import CoreVideo
import UIKit

final class VideoModel: ObservableObject {
    enum Error: Swift.Error {
        case indexOutOfRange
        case compositionVideoTrackFailed
        case invalidVideoAsset(_ asset: AVAsset)
    }

    let reelConfig: VideoConfigiration = .preview
    
    @Published private(set) var isRegeneratingComposition = false
    @Published private(set) var items: [any FrameItem] = []

    var createPlayerItem: AVPlayerItem { AVPlayerItem(asset: composition) }
    var isReady: Bool { isRegeneratingComposition == false }
    var duration: CMTime { items.reduce(CMTime.zero, { CMTimeAdd($0, $1.duration) }) }

    private var composition = AVMutableComposition()

    private func compositionDefaultTrack(for mediaType: AVMediaType) -> AVMutableCompositionTrack? {
        if let compatibleTrack = composition.tracks(withMediaType: mediaType).first {
            return compatibleTrack
        } else if let mutableTrack = composition.addMutableTrack(
            withMediaType: mediaType,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) {
            return mutableTrack
        } else {
            return nil
        }
    }

    deinit {
        reelConfig.cleanupWorkingDirectory()
    }
}

// MARK: - Append

extension VideoModel {
    func append(from source: FrameItemSource) async throws {
        switch source {
        case let image as UIImage:
            try await append(image: image)
        case let asset as AVAsset:
            try await append(asset: asset)
        default:
            fatalError("unknown reel item source: \(source)")
        }
    }
    
    func append(image: UIImage) async throws {
        let item = FrameImageItem(image: image)
        try await appendItem(item)
    }

    func append(asset: AVAsset) async throws {
        let videoItem = FrameVideoItem(asset: asset)
        try await appendItem(videoItem)
    }

    private func appendItem(_ item: any FrameItem) async throws {
        Task { @MainActor in
            items.append(item)
            isRegeneratingComposition = true
        }
        
        try await resolveItem(item, at: items.count)
        
        Task { @MainActor in
            isRegeneratingComposition = false
        }
    }
}

// MARK: - Resolve

extension VideoModel {
    private func resolveItem(_ item: any FrameItem, at index: Int) async throws {
        let videoAsset = try await item.generateAsset(config: reelConfig)
        return try await insertVideo(videoAsset, at: index)
    }
}

// MARK: - Replace

extension VideoModel {
    func replaceItem(at index: Int, with source: FrameItemSource) async throws {
        switch source {
        case let image as UIImage:
            try await replaceItem(at: index, with: image)
        case let asset as AVAsset:
            try await replaceItem(at: index, with: asset)
        default:
            fatalError("Unhandled FrametemSource: \(source)")
        }
    }

    func replaceItem(at index: Int, with image: UIImage) async throws {
        let newImageItem = FrameImageItem(image: image)
        try await replaceItem(at: index, with: newImageItem)
    }

    func replaceItem(at index: Int, with asset: AVAsset) async throws {
        let newVideoItem = FrameVideoItem(asset: asset)
        try await replaceItem(at: index, with: newVideoItem)
    }

    func replaceItem(at index: Int, with item: any FrameItem) async throws {
        guard items.indices.contains(index) else { throw Error.indexOutOfRange }
        
        let currentItem = items[index]
        items[index] = item

        assert(item.duration == currentItem.duration)

        isRegeneratingComposition = true
        let videoAsset = try await item.generateAsset(config: reelConfig)
        try await replaceVideo(at: index, with: videoAsset)
        isRegeneratingComposition = false
    }
    
    private func replaceVideo(at index: Int, with asset: AVAsset) async throws {
        let assetDuration = try await asset.load(.duration)
        let assetTimeRange = CMTimeRange(start: .zero, duration: assetDuration)
        let timeRange = CMTimeRange(start: startTimeForIndex(index), duration: assetTimeRange.duration)

        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw Error.invalidVideoAsset(asset)
        }
        
        guard let compositionTrack = compositionDefaultTrack(for: videoTrack.mediaType) else {
            throw Error.compositionVideoTrackFailed
        }

        compositionTrack.removeTimeRange(timeRange)
        try await insertVideo(asset, at: index)
    }
}

// MARK: - Other

extension VideoModel {
    func moveItem(at sourceIndex: Int, to destinationIndex: Int) {
        let item = items.remove(at: sourceIndex)
        items.insert(item, at: destinationIndex)
        
        isRegeneratingComposition = true
        Task(priority: .userInitiated) {
            try await regenerateComposition()
            
            Task { @MainActor in
                isRegeneratingComposition = false
            }
        }
    }
    
    func updateItem(at index: Int, with image: UIImage) async throws {
        // TODO: Use crop rect instead of variable source image
        let currentItem = items[index] as? FrameImageItem

        let newImageItem = FrameImageItem(image: image)

        if let currentItem {
            newImageItem.sourceImage = currentItem.sourceImage
        }

        try await replaceItem(at: index, with: newImageItem)
    }
    
    func removeItem(at index: Int) {
        items.remove(at: index)
        
        isRegeneratingComposition = true
        Task(priority: .userInitiated) {
            try await regenerateComposition()
            
            Task { @MainActor in
                isRegeneratingComposition = false
            }
        }
    }
    
//    func trimVideoItem(at index: Int, trimRange: CMTimeRange) async throws {
//        guard let currentItem = items[index] as? FrameVideoItem else {
//            return
//        }
//
//        let newTimeRange = CMTimeRange(start: trimRange.start, duration: currentItem.duration)
//        let newVideoItem = FrameVideoItem(asset: currentItem.sourceAsset, timeRange: timeRange)
//
//        try await replaceItem(at: index, with: newVideoItem)
//    }
//
//    func cropVideoItem(at index: Int, cropRect _: CGRect) async throws {
//        guard let currentItem = items[index] as? FrameVideoItem else { return }
//        // TODO: Implement video cropping
//    }

//    private func frameDuration(for idx: Int) -> CMTime {
//        assert(template.frameDurations.indices.contains(idx))
//        return CMTime(seconds: template.frameDurations[idx])
//    }
    
    // Insert audio
    func insertAudio(audioURL: URL) throws {
        let audioAsset = AVAsset(url: audioURL)
        try composition.addTracks(
            .audio,
            from: audioAsset,
            trim: CMTimeRange(start: .zero, duration: duration)
        )
    }
}

// MARK: - Private

extension VideoModel {
    private func insertVideo(_ asset: AVAsset, at index: Int) async throws {
        let assetTracks = try await asset.loadTracks(withMediaType: .video)

        for assetTrack in assetTracks {
            let trackTimeRange = try await assetTrack.load(.timeRange)
            let startTime = startTimeForIndex(index)
            let mutableTrack = compositionDefaultTrack(for: assetTrack.mediaType)
            try mutableTrack?.insertTimeRange(
                CMTimeRange(start: .zero, duration: trackTimeRange.duration),
                of: assetTrack,
                at: startTime
            )
        }
    }

    private func regenerateComposition() async throws {
        if let compositionVideoTrack = compositionDefaultTrack(for: .video) {
            compositionVideoTrack.removeTimeRange(
                CMTimeRange(start: .zero, duration: compositionVideoTrack.timeRange.duration)
            )
        }

        for (index, item) in items.enumerated() {
            try await resolveItem(item, at: index)
        }
    }

    private func startTimeForIndex(_ index: Int) -> CMTime {
        return items.prefix(upTo: index).reduce(CMTime.zero) { partialResult, reelItem in
            CMTimeAdd(partialResult, reelItem.duration)
        }
    }

    private func endTimeForIndex(_ index: Int) -> CMTime {
        assert(index >= 0 && index < items.count, "Index out of range")
        return items.prefix(through: index).reduce(CMTime.zero) { partialResult, reelItem in
            CMTimeAdd(partialResult, reelItem.duration)
        }
    }
}
