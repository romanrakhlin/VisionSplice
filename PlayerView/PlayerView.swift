//
//  PlayerView.swift
//  SwiftStudentChallenge2024
//
//  Created by Roman Rakhlin on 2/5/24.
//

import SwiftUI
import AVFoundation

protocol ReelPlayerViewDelegate: AnyObject {
    func reelPlayerDidUpdatePlayback(_ reelPlayer: PlayerView, time: CMTime)
}

struct PlayerView: View {
    
    @StateObject var videoPlayer: PlayerViewModel
    
    init(url: URL) {
        _videoPlayer = StateObject(wrappedValue: PlayerViewModel(url: url))
//        videoPlayer.player.isMuted = false
//        videoPlayer.loop = true
//        videoPlayer.timeObserverHandler = { time in
//            updatePlaybackProgress(withTime: time)
//        }
    }
    
    // MARK: - Public

    public var addItemAction: (() -> Void)?
    
    public var asset: AVAsset? { videoPlayer.asset }
    
    public var playerItem: AVPlayerItem? {
        set {
            videoPlayer.playerItem = newValue

            if newValue != nil {
                assetState = .ready
            } else {
                assetState = .empty
            }
        }
        get { videoPlayer.playerItem }
    }

    public var loop: Bool {
        set { videoPlayer.loop = newValue }
        get { videoPlayer.loop }
    }

    public var rate: Float {
        set {
            videoPlayer.player.rate = newValue
            videoPlayer.player.playImmediately(atRate: newValue)
        }
        get { videoPlayer.player.rate }
    }

    public var isMuted: Bool {
        set { videoPlayer.player.isMuted = newValue }
        get { videoPlayer.player.isMuted }
    }

    @State var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    
//    public var showsMuteButton: Bool {
//        get { !volumeButton.isHidden }
//        set { volumeButton.isHidden = !newValue }
//    }
//
//    public var isCompact: Bool = false {
//        didSet {
//            actionButton.isHidden = isCompact
//        }
//    }

    public weak var delegate: ReelPlayerViewDelegate?

    private var isControlsHidden = false

    @State private(set) var assetState: AssetState = .empty {
        willSet {
            guard newValue != assetState else {
                return
            }
            switchAssetState(to: newValue)
        }
    }
    
    @State private(set) var playbackState: PlaybackState = .stopped {
        willSet {
            guard newValue != playbackState else {
                return
            }
            switchPlaybackState(to: newValue)
        }
    }
    
    public var body: some View {
        ZStack {
            AVPlayerLayerViewRepresentable(player: $videoPlayer.player, videoGravity: $videoGravity)
                .onTapGesture {
                    guard assetState != .loading else {
                        return
                    }
                    guard assetState != .empty else {
                        addItemAction?()
                        return
                    }

                    switch playbackState {
                    case .stopped, .paused:
                        play()
                    case .playing:
                        pause()
                    }
                }
        }
        .onAppear(perform: setup)
    }
    
    private func setup() {
        // Setup Audio Session
        do {
            try AudioSession.setupForPlayback()
        } catch {
            print(error.localizedDescription)
        }
        
        // Setup Player
        videoPlayer.player.isMuted = false
        videoPlayer.loop = true
        videoPlayer.play()
    }
}

// MARK: - Public Functions

extension PlayerView {
    public var isPlaying: Bool { playbackState == .playing }

    public func setLoading() {
        assetState = .loading
    }

    public func setReady() {
        assetState = .ready
    }

    public func play() {
        playbackState = .playing
        videoPlayer.play()
    }

    public func pause() {
        playbackState = .paused
        videoPlayer.pause()
    }

    public func stop() {
        playbackState = .paused
        videoPlayer.stop()
    }

    public func seekToStart() {
        videoPlayer.seekToStart()
    }

    public func seekTo(time: CMTime) {
        videoPlayer.seekTo(time: time)
        updatePlaybackProgress(withTime: time)
    }

    public func setShowsControls(_ show: Bool, animated: Bool) {
        let isShowing = !isControlsHidden
        guard show != isShowing else {
            return
        }
//        toggleControlsVisibilty(animated)
    }
}

//// MARK: - Actions
//
//extension PlayerView {
//    @objc
//    private func didTapVolumeButton(_ sender: GlamButton) {
//        isMuted.toggle()
//
//        let image = isMuted ? Images.Volume.unmute : Images.Volume.mute
//        sender.setImage(image, for: .normal)
//    }
//}

// MARK: - Helpers

extension PlayerView {
    private func updatePlaybackProgress(withTime time: CMTime) {
//        guard let asset else {
//            playingTimeLabel.text = "00:00"
//            overallDurationLabel.text = "00:00"
//            progressView.setProgress(0, animated: true)
//
//            return
//        }
//
//        let assetDuration = asset.duration.seconds
//        let currentTime = time.seconds
//        assert(assetDuration.isFinite)
//        assert(currentTime.isFinite)
//        guard assetDuration.isFinite, currentTime.isFinite else {
//            return
//        }
//
//        let progress = Float(currentTime / assetDuration)
//
//        playingTimeLabel.text = timeFormatter.string(from: currentTime)
//        overallDurationLabel.text = timeFormatter.string(from: assetDuration)
//        progressView.setProgress(progress, animated: false)
//
//        delegate?.reelPlayerDidUpdatePlayback(self, time: time)
    }
}

// MARK: - States

extension PlayerView {
    private func switchAssetState(to newState: AssetState) {
//        switch newState {
//        case .empty:
//            actionButton.setImage(Images.Common.plus, for: .normal)
//            actionButton.mode = .normal
//
//            UIView.animate(
//                withDuration: 0.15,
//                delay: 0,
//                options: [.allowUserInteraction, .beginFromCurrentState],
//                animations: { [self] in
//                    volumeButton.alpha = 0
//                    playingTimeLabel.alpha = 0
//                    overallDurationLabel.alpha = 0
//                    progressView.alpha = 0
//                }
//            )
//        case .loading:
//            actionButton.mode = .loading
//
//            UIView.animate(
//                withDuration: 0.15,
//                delay: 0,
//                options: [.allowUserInteraction, .beginFromCurrentState],
//                animations: { [self] in
//                    volumeButton.alpha = 0
//                    playingTimeLabel.alpha = 0
//                    overallDurationLabel.alpha = 0
//                    progressView.alpha = 0
//                }
//            )
//        case .ready:
//            actionButton.setImage(Images.Playback.play, for: .normal)
//            actionButton.mode = .normal
//
//            UIView.animate(
//                withDuration: 0.15,
//                delay: 0,
//                options: [.allowUserInteraction, .beginFromCurrentState],
//                animations: { [self] in
//                    volumeButton.alpha = 1
//                    playingTimeLabel.alpha = 1
//                    overallDurationLabel.alpha = 1
//                    progressView.alpha = 1
//                }
//            )
//        }
    }

    private func switchPlaybackState(to newState: PlaybackState) {
//        switch newState {
//        case .stopped, .paused:
//            actionButton.setImage(Images.Playback.play, for: .normal)
//        case .playing:
//            actionButton.setImage(Images.Playback.pause, for: .normal)
//        }
    }
}

// MARK: - Gestures

//extension PlayerView {
//    @objc
//    private func handleControlsViewTap(_: UIGestureRecognizer) {
//        toggleControlsVisibilty(true)
//    }
//
//    private func toggleControlsVisibilty(_ animated: Bool) {
//        isControlsHidden.toggle()
//
//        let animationDuration: TimeInterval = animated ? 0.15 : 0
//        UIView.animate(
//            withDuration: animationDuration,
//            delay: 0,
//            options: [.allowUserInteraction, .beginFromCurrentState],
//            animations: { [self] in
//                controlsView.alpha = isControlsHidden ? 0 : 1
//            }
//        )
//    }
//}

// MARK: - Structs

extension PlayerView {
    enum AssetState {
        case empty
        case loading
        case ready
    }

    enum PlaybackState {
        case stopped
        case paused
        case playing
    }

    private enum Images {
        enum Common {
            static let plus = systemImage(name: "plus", pointSize: 32)
        }

        enum Playback {
            static let play = systemImage(name: "play.fill", pointSize: 50)
            static let pause = systemImage(name: "pause.fill", pointSize: 50)
        }

        enum Volume {
            static let mute = systemImage(name: "speaker.wave.2.fill", pointSize: 20)
            static let unmute = systemImage(name: "speaker.slash.fill", pointSize: 20)
        }

        private static func systemImage(name: String, pointSize: CGFloat) -> UIImage {
            let imageConfig = UIImage.SymbolConfiguration(
                pointSize: pointSize,
                weight: .regular
            )

            return UIImage(
                systemName: name,
                withConfiguration: imageConfig
            )!
        }
    }
}
