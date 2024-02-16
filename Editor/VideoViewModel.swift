//
//  VideoViewModel.swift
//
//
//  Created by Roman Rakhlin on 2/6/24.
//

import AVFoundation
import Combine
import CoreVideo
import UIKit

final class VideoViewModel: ObservableObject {
    enum Error: Swift.Error {
        case indexOutOfRange
        case compositionVideoTrackFailed
        case invalidVideoAsset(_ asset: AVAsset)
    }

    let previewConfigiration: VideoConfigiration = .preview
    let exportConfigiration: VideoConfigiration = .export
    
    @Published private(set) var isRegeneratingComposition = false
    @Published private(set) var items: [any FrameItem] = []
    
    private var composition = AVMutableComposition()

    var createPlayerItem: AVPlayerItem { AVPlayerItem(asset: composition) }
    var isReady: Bool { isRegeneratingComposition == false }
    var duration: CMTime { items.reduce(CMTime.zero, { CMTimeAdd($0, $1.duration) }) }

    deinit {
        previewConfigiration.cleanupWorkingDirectory()
    }
}

// MARK: - Append

extension VideoViewModel {
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

extension VideoViewModel {
    private func resolveItem(_ item: any FrameItem, at index: Int) async throws {
        let videoAsset = try await item.generateAsset(config: previewConfigiration)
        return try await insertVideo(videoAsset, at: index)
    }
}

// MARK: - Replace

extension VideoViewModel {
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
        
        Task { @MainActor in
            items[index] = item
            isRegeneratingComposition = true
        }
        
        let videoAsset = try await item.generateAsset(config: previewConfigiration)
        try await replaceVideo(at: index, with: videoAsset)
        
        Task { @MainActor in
            isRegeneratingComposition = false
        }
    }
    
    private func replaceVideo(at index: Int, with asset: AVAsset) async throws {
        let assetDuration = try await asset.load(.duration)
        let assetTimeRange = CMTimeRange(start: .zero, duration: assetDuration)
        let timeRange = CMTimeRange(start: startTimeForIndex(index), duration: assetTimeRange.duration)

        // Handle video track
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else { throw Error.invalidVideoAsset(asset) }
        guard let compositionVideoTrack = compositionDefaultTrack(for: videoTrack.mediaType) else { throw Error.compositionVideoTrackFailed }
        compositionVideoTrack.removeTimeRange(timeRange)
        
        // Handle audio track
        guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else { throw Error.invalidVideoAsset(asset) }
        guard let compositionAudioTrack = compositionDefaultTrack(for: audioTrack.mediaType) else { throw Error.compositionVideoTrackFailed }
        compositionAudioTrack.removeTimeRange(timeRange)
        
        try await insertVideo(asset, at: index)
    }
}

// MARK: - Other

extension VideoViewModel {
    public func moveItem(at sourceIndex: Int, to destinationIndex: Int) {
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
    
    public func removeItem(at index: Int) {
        items.remove(at: index)
        
        isRegeneratingComposition = true
        Task(priority: .userInitiated) {
            try await regenerateComposition()
            
            Task { @MainActor in
                isRegeneratingComposition = false
            }
        }
    }
    
    public func insertAudio(audioURL: URL) throws {
        let audioAsset = AVAsset(url: audioURL)
        try composition.addTracks(
            .audio,
            from: audioAsset,
            trim: CMTimeRange(start: .zero, duration: duration)
        )
    }
}

// MARK: - Helpers

extension VideoViewModel {
    public func indexForItem(_ item: any FrameItem) -> Int? {
        items.firstIndex(where: { $0.id == item.id })
    }
}

// MARK: - Export

extension VideoViewModel {
    public func export() async throws -> AVPlayerItem {
        let (exportSession, outputVideoFileURL) = VideoCompositor
            .prepareDefaultExportSessionAndFileURL(
                asset: composition,
                quality: exportConfigiration.quality,
                storeDirectory: exportConfigiration.exportDirectoryURL,
                fileName: UUID().uuidString
            )

        await exportSession.export()
        if let error = exportSession.error { throw error }
        return AVPlayerItem(url: outputVideoFileURL)
    }
}

// MARK: - Private

extension VideoViewModel {
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
    
    private func insertVideo(_ asset: AVAsset, at index: Int) async throws {
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        
        // add video tracks
        for track in videoTracks {
            let trackTimeRange = try await track.load(.timeRange)
            let startTime = startTimeForIndex(index)
            let mutableTrack = compositionDefaultTrack(for: track.mediaType)
            try mutableTrack?.insertTimeRange(
                CMTimeRange(start: .zero, duration: trackTimeRange.duration),
                of: track,
                at: startTime
            )
        }
        
        // add audio tracks
        for track in audioTracks {
            let trackTimeRange = try await track.load(.timeRange)
            let startTime = startTimeForIndex(index)
            let mutableTrack = compositionDefaultTrack(for: track.mediaType)
            try mutableTrack?.insertTimeRange(
                CMTimeRange(start: .zero, duration: trackTimeRange.duration),
                of: track,
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
        
        if let compositionAudioTrack = compositionDefaultTrack(for: .audio) {
            compositionAudioTrack.removeTimeRange(
                CMTimeRange(start: .zero, duration: compositionAudioTrack.timeRange.duration)
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
