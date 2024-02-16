//
//  VideoPlayerView.swift
//  SwiftStudentChallenge2024
//
//  Created by Roman Rakhlin on 2/5/24.
//

import SwiftUI
import AVFoundation

struct VideoPlayerView: View {
    
    @ObservedObject var viewModel: VideoPlayerViewModel
    
    @State private var playingTime: String?
    @State private var overallDuration: String?
    @State private var videoProgress = 0.0
    
    private var asset: AVAsset? { viewModel.asset }
    
    public var body: some View {
        ZStack {
            AVPlayerLayerViewRepresentable(player: $viewModel.player, videoGravity: $viewModel.videoGravity)
                .onTapGesture {
                    guard viewModel.assetState == .ready, !viewModel.isPauseDisabled else { return }
                    
                    switch viewModel.playbackState {
                    case .stopped, .paused:
                        play()
                    case .playing:
                        pause()
                    }
                }
                
            if viewModel.assetState == .ready && !viewModel.isPauseDisabled {
                Rectangle()
                    .fill(.clear)
                    .background {
                        if viewModel.playbackState == .playing {
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
            }
            
//            switch $viewModel.assetState {
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
            
            if viewModel.showProgress {
                VStack {
                    Spacer()
                    
                    ProgressView(value: videoProgress, total: 1)
                        .accentColor(Constants.primaryColor)
                        .scaleEffect(x: 1, y: 4, anchor: .center)
                }
            }
        }
        .onAppear(perform: setup)
        .onDisappear(perform: viewModel.invalidate)
    }
    
    private func setup() {
        // Setup Audio Session
        do {
            try AudioSession.setupForPlayback()
        } catch {
            print(error.localizedDescription)
        }
        
        // Setup Player
        viewModel.player.isMuted = false
        viewModel.loop = true
        viewModel.play()
        
        // Time observer
        viewModel.timeObserverHandler = { time in
            updatePlaybackProgress(withTime: time)
        }
    }
}

// MARK: - Helpers

extension VideoPlayerView {
    public func setLoading() {
        viewModel.assetState = .loading
    }
    
    private func play() {
        viewModel.playbackState = .playing
        viewModel.play()
    }

    private func pause() {
        viewModel.playbackState = .paused
        viewModel.pause()
    }
    
    private func stop() {
        viewModel.playbackState = .paused
        viewModel.stop()
    }

    private func seekToStart() {
        viewModel.seekToStart()
    }

    private func seekTo(time: CMTime) {
        viewModel.seekTo(time: time)
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
