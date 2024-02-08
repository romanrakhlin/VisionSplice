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

    public var createPlayerItem: AVPlayerItem { AVPlayerItem(asset: composition) }

    @Published private(set) var isRegeneratingComposition: CurrentValueSubject<Bool, Never> = .init(false)
    @Published private(set) var items: [any FrameItem] = []
    @Published private(set) var dummyItems: [any FrameItem] = [
        FrameImageItem(image: UIImage(named: "Pumpkin")!),
        FrameImageItem(image: UIImage(named: "Pumpkin")!),
        FrameImageItem(image: UIImage(named: "Pumpkin")!)
    ]

    var emptyItemsCount: Int { items.filter { $0 is FrameEmptyItem }.count }

    var hasContent: Bool { !items.filter { !($0 is FrameEmptyItem) }.isEmpty }

    var isReady: Bool { isRegeneratingComposition.value == false }
    
    var duration: CMTime { CMTime(seconds: items.reduce(TimeInterval.zero, { $0 + $1.duration.seconds })) }

    private var composition = AVMutableComposition()

    private func compositionDefaultTrack(for mediaType: AVMediaType)
        -> AVMutableCompositionTrack?
    {
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

extension VideoModel {
    // Insert
    func insertEmptyItem(at index: Int) async throws {
        let emptyItem = FrameEmptyItem()
        try await insertItem(emptyItem, at: index)
    }

    func insert(image: UIImage, at index: Int) async throws {
        let item = FrameImageItem(image: image)
        try await insertItem(item, at: index)
    }

    func insert(asset: AVAsset, at index: Int) async throws {
        let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        let videoItem = FrameVideoItem(asset: asset)
        try await insertItem(videoItem, at: index)
    }

    private func insertItem(_ item: any FrameItem, at index: Int) async throws {
        guard index >= 0 && index <= items.count else {
            throw Error.indexOutOfRange
        }

        items.insert(item, at: index)

        isRegeneratingComposition.value = true
        try await resolveItem(item, at: index)
        isRegeneratingComposition.value = false
    }

    private func resolveItem(_ item: any FrameItem, at index: Int) async throws {
        let videoAsset = try await item.generateAsset(config: reelConfig)
        return try insertVideo(videoAsset, at: index)
    }

    // Move
    func moveItem(at sourceIndex: Int, to destinationIndex: Int) {
        let item = items.remove(at: sourceIndex)
        items.insert(item, at: destinationIndex)

        Task(priority: .userInitiated) {
            isRegeneratingComposition.value = true
            try await regenerateComposition()
            isRegeneratingComposition.value = false
        }
    }

    // Clear
    func clearItem(at index: Int) async throws {
        guard items.indices.contains(index) else {
            throw Error.indexOutOfRange
        }
        let item = items[index]
        let emptyItem = FrameEmptyItem()
        try await replaceItem(at: index, with: emptyItem)
    }

    // Replace
    func replaceItem(at index: Int, with source: FrameItemSource) async throws {
        switch source {
        case let image as UIImage:
            try await replaceItem(at: index, with: image)
        case let asset as AVAsset:
            try await replaceItem(at: index, with: asset)
        default:
            fatalError("Unhandled ReelItemSource: \(source)")
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

    func replaceEmptyItems(from idx: Int, with sources: [FrameItemSource]) async throws -> [Int] {
        var sources = Array(sources.reversed())
        var replacedIndices: [Int] = []

        // Cycle through items starting from the idx and replace empty items with sources
        for idx in idx ..< items.count + idx {
            if sources.isEmpty {
                break
            }

            let idx = idx % items.count
            let item = items[idx]
            guard item is FrameEmptyItem else {
                continue
            }
            let nextSource = sources.removeLast() // popping actually
            try await replaceItem(at: idx, with: nextSource)
            replacedIndices.append(idx)
        }

        return replacedIndices
    }

    func replaceItem(
        at index: Int,
        with item: any FrameItem
    ) async throws {
        guard items.indices.contains(index) else {
            throw Error.indexOutOfRange
        }
        let currentItem = items[index]
        items[index] = item

        assert(item.duration == currentItem.duration)

        isRegeneratingComposition.value = true
        let videoAsset = try await item.generateAsset(config: reelConfig)

        try replaceVideo(at: index, with: videoAsset)
        isRegeneratingComposition.value = false
    }

    // Update
    func updateItem(at index: Int, with image: UIImage) async throws {
        // TODO: Use crop rect instead of variable source image
        let currentItem = items[index] as? FrameImageItem

        let newImageItem = FrameImageItem(image: image)

        if let currentItem {
            newImageItem.sourceImage = currentItem.sourceImage
        }

        try await replaceItem(at: index, with: newImageItem)
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
        try insertAudio(AVAsset(url: audioURL))
    }
}

extension VideoModel {
    func insert(from source: FrameItemSource, at index: Int) async throws {
        switch source {
        case let image as UIImage:
            try await insert(image: image, at: index)
        case let asset as AVAsset:
            try await insert(asset: asset, at: index)
        default:
            fatalError("unknown reel item source: \(source)")
        }
    }
}

// MARK: - Private

extension VideoModel {
    private func insertAudio(_ asset: AVAsset) throws {
        try composition.addTracks(
            .audio,
            from: asset,
            trim: CMTimeRange(
                start: .zero,
                duration: duration
            )
        )
    }

    private func insertVideo(_ asset: AVAsset, at index: Int) throws {
        let assetTracks = asset.tracks(withMediaType: .video)

        for assetTrack in assetTracks {
            let trackTimeRange = assetTrack.timeRange
            let startTime = startTimeForIndex(index)
            let mutableTrack = compositionDefaultTrack(for: assetTrack.mediaType)
            try mutableTrack?.insertTimeRange(
                CMTimeRange(start: .zero, duration: trackTimeRange.duration),
                of: assetTrack,
                at: startTime
            )
        }
    }

    private func replaceVideo(at index: Int, with asset: AVAsset) throws {
        let assetTimeRange = CMTimeRange(start: .zero, duration: asset.duration)
        let timeRange = CMTimeRange(
            start: startTimeForIndex(index),
            duration: assetTimeRange.duration
        )

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            throw Error.invalidVideoAsset(asset)
        }
        guard let compositionTrack = compositionDefaultTrack(for: videoTrack.mediaType) else {
            throw Error.compositionVideoTrackFailed
        }

        compositionTrack.removeTimeRange(timeRange)
        try insertVideo(asset, at: index)
    }

    private func regenerateComposition() async throws {
        if let compositionVideoTrack = compositionDefaultTrack(for: .video) {
            compositionVideoTrack.removeTimeRange(
                CMTimeRange(
                    start: .zero,
                    duration: compositionVideoTrack.timeRange.duration
                )
            )
        }

        for (idx, item) in items.enumerated() {
            try await resolveItem(item, at: idx)
        }
    }

    private func startTimeForIndex(_ index: Int) -> CMTime {
        assert(index >= 0 && index <= items.count, "Index out of range")
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
