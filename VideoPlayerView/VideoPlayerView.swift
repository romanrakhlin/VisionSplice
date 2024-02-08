//
//  VideoPlayerView.swift
//  SwiftStudentChallenge2024
//
//  Created by Roman Rakhlin on 2/5/24.
//

import SwiftUI
import AVFoundation

struct VideoPlayerView: View {
    
    @ObservedObject var model: VideoPlayerViewModel
    
    var addItemAction: (() -> Void)?
    
    @State var playingTime: String?
    @State var overallDuration: String?
    @State var videoProgress = 0.0
    
    private var asset: AVAsset? { model.asset }
    
    public var body: some View {
        ZStack {
            AVPlayerLayerViewRepresentable(player: $model.player, videoGravity: $model.videoGravity)
                .onTapGesture {
                    guard model.assetState != .loading else {
                        return
                    }
                    guard model.assetState != .empty else {
                        addItemAction?()
                        return
                    }

                    switch model.playbackState {
                    case .stopped, .paused:
                        play()
                    case .playing:
                        pause()
                    }
                }
                
            if model.assetState == .ready {
                if model.playbackState == .playing {
                    Button {
                        pause()
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(Constants.primaryColor)
                    }
                } else {
                    Button {
                        play()
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(Constants.primaryColor)
                    }
                }
            }
            
//            switch $model.assetState {
//            case .empty:
//            case .loading:
//            case .ready:
//            }
            
//            switch newState {
//            case .stopped, .paused:
//                actionButton.setImage(Images.Playback.play, for: .normal)
//            case .playing:
//                actionButton.setImage(Images.Playback.pause, for: .normal)
//            }
            
            VStack {
                Spacer()
                
                ProgressView(value: videoProgress, total: 1)
                    .accentColor(Constants.primaryColor)
                    .scaleEffect(x: 1, y: 4, anchor: .center)
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
        model.player.isMuted = false
        model.loop = true
        model.play()
        
        // Time observer
        model.timeObserverHandler = { time in
            updatePlaybackProgress(withTime: time)
        }
    }
}

// MARK: - Helpers

extension VideoPlayerView {
    public func setLoading() {
        model.assetState = .loading
    }
    
    private func play() {
        model.playbackState = .playing
        model.play()
    }

    private func pause() {
        model.playbackState = .paused
        model.pause()
    }
    
    private func stop() {
        model.playbackState = .paused
        model.stop()
    }

    private func seekToStart() {
        model.seekToStart()
    }

    private func seekTo(time: CMTime) {
        model.seekTo(time: time)
        updatePlaybackProgress(withTime: time)
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

extension VideoPlayerView {
    private func updatePlaybackProgress(withTime time: CMTime) {
        guard let asset else {
            playingTime = "00:00"
            overallDuration = "00:00"
            videoProgress = 0.0

            return
        }

        let assetDuration = asset.duration.seconds
        let currentTime = time.seconds
        assert(assetDuration.isFinite)
        assert(currentTime.isFinite)
        guard assetDuration.isFinite, currentTime.isFinite else { return }

        let progress = Double(currentTime / assetDuration)

        let timeFormatter = DateComponentsFormatter()
        timeFormatter.allowedUnits = [.minute, .second]
        timeFormatter.zeroFormattingBehavior = .pad
        
        playingTime = timeFormatter.string(from: currentTime)
        overallDuration = timeFormatter.string(from: assetDuration)
        videoProgress = min(progress, 1)
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
