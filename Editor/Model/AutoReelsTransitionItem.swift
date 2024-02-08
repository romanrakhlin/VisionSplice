//
//  File.swift
//  
//
//  Created by Roman Rakhlin on 2/6/24.
//

import AVFoundation
import CoreVideo

//final class AutoReelsTransitionItem: ReelItem {
//    typealias SegmentationProvider = (CVPixelBuffer) async throws -> (CGImage, CVPixelBuffer)
//
//    struct Config {
//        let backgroundSegmentationProvider: SegmentationProvider
//        let animationDuration: CMTime
//        let postAnimationDelayDuration: CMTime
//    }
//
//    let previous: CVPixelBuffer
//    let next: CVPixelBuffer
//    let transitionConfig: Config
//
//    var duration: CMTime {
//        CMTimeAdd(transitionConfig.animationDuration, transitionConfig.postAnimationDelayDuration)
//    }
//
//    private static let transitionResolver = TransitionResolver()
//
//    init(previous: CVPixelBuffer, next: CVPixelBuffer, transitionConfig: Config) {
//        self.previous = previous
//        self.next = next
//        self.transitionConfig = transitionConfig
//    }
//
//    func generateAsset(config: ReelConfig) async throws -> AVAsset {
//        let (foreground, mask) = try await transitionConfig.backgroundSegmentationProvider(next)
//        let transitionKind = Self.transitionResolver.transition(
//            for: mask,
//            renderSize: config.videoSize
//        )
//
//        let background = try await VideoCompositor.makeStillVideo(
//            fromImage: previous,
//            duration: transitionConfig.animationDuration.seconds,
//            renderSize: config.videoSize,
//            fps: config.fps,
//            bitrate: config.bitrate,
//            storeDirectory: config.workingDirectoryURL,
//            outputName: UUID().uuidString
//        )
//
//        let animation = try await VideoCompositor.makeTransition(
//            background: AVURLAsset(url: background),
//            foreground: foreground,
//            animation: transitionKind,
//            renderSize: config.videoSize,
//            fps: config.fps,
//            quality: config.quality,
//            storeDirectory: config.workingDirectoryURL,
//            outputName: UUID().uuidString
//        )
//
//        let postAnimationBackground = try await VideoCompositor.makeStillVideo(
//            fromImage: previous,
//            duration: transitionConfig.postAnimationDelayDuration.seconds,
//            renderSize: config.videoSize,
//            fps: config.fps,
//            bitrate: config.bitrate,
//            storeDirectory: config.workingDirectoryURL,
//            outputName: UUID().uuidString
//        )
//
//        let postAnimation = try await VideoCompositor.makeTransition(
//            background: AVURLAsset(url: postAnimationBackground),
//            foreground: foreground,
//            animation: .noAnimation,
//            renderSize: config.videoSize,
//            fps: config.fps,
//            quality: config.quality,
//            storeDirectory: config.workingDirectoryURL,
//            outputName: UUID().uuidString
//        )
//
//        let merged = try await VideoCompositor.mergeVideos(
//            [animation, postAnimation],
//            storeDirectory: config.workingDirectoryURL,
//            outputName: UUID().uuidString
//        )
//
//        return AVURLAsset(url: merged)
//    }
//
//    func generateThumbnail() async throws -> UIImage { UIImage() }
//
//    func item(with _: CMTimeRange) -> AutoReelsTransitionItem { self }
//}
