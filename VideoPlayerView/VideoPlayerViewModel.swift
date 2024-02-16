//
//  VideoPlayerViewModel.swift
//  SwiftStudentChallenge2024
//
//  Created by Roman Rakhlin on 2/5/24.
//

import SwiftUI
import Combine
import AVFoundation

final class VideoPlayerViewModel: NSObject, ObservableObject {
    
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
    
    @Published var player = AVPlayer()
    @Published var shouldPlay = false
    @Published var startedPlaying = false
    @Published var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    @Published var loop = true
    @Published var playbackState: PlaybackState = .playing
    @Published var assetState: AssetState = .empty
    @Published var isPauseDisabled = false
    @Published var showProgress = true
    
    var asset: AVAsset? { playerItem?.asset }
    
    // Observation
    @Published var timeObserverHandler: ((CMTime) -> Void)?
    private var playerPeriodicTimeObserver: Any?
    private var subscriptions = Set<AnyCancellable>()
    
    @Published var playerItem: AVPlayerItem? {
        willSet {
            if playerItem != newValue {
                removeObservers(playerItem: playerItem)
                setupObservers(playerItem: newValue)
            }
            
            if newValue != nil {
                assetState = .ready
            } else {
                assetState = .empty
            }
        }
    }
    
    deinit {
        removeObservers(playerItem: playerItem)
    }
    
    func play() {
        shouldPlay = true
        player.play()
    }
    
    func pause() {
        shouldPlay = false
        player.pause()
    }
    
    func stop() {
        pause()
        seekTo(time: .zero)
    }
    
    func seekTo(time: CMTime) {
        guard player.status == .readyToPlay, playerItem?.status == .readyToPlay else { return }
        player.seek(to: time)
    }
    
    func seekToStart() {
        seekTo(time: .zero)
    }
    
    func invalidate() {
        player.seek(to: .zero)
        player.pause()
        player.replaceCurrentItem(with: nil)
    }
}

// MARK: - Observation

extension VideoPlayerViewModel {
    private func setupObservers(playerItem: AVPlayerItem?) {
        guard let playerItem else { return }
        
        self.startedPlaying = false
        
        let asset = playerItem.asset
        let durationKey = "duration"
        let playableKey = "playable"
        let tracksKey = "tracks"
        let preferredTransformKey = "preferredTransform"
        let durationLoaded = (asset.statusOfValue(forKey: durationKey, error: nil) == .loaded)
        
        var keys: [String] = [playableKey, tracksKey, preferredTransformKey]
        if !durationLoaded {
            keys.append(durationKey)
        }
        
        asset.loadValuesAsynchronously(forKeys: keys) { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                if self.asset == asset {
                    self.player.replaceCurrentItem(with: playerItem)
                }
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePlayerItemDidPlayToEndNotification), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        setupPlayerTimeObserver()
    }
    
    private func removeObservers(playerItem: AVPlayerItem?) {
        guard let playerItem = playerItem else { return }
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        removePlayerTimeObserver()
    }
    
    private func setupPlayerTimeObserver() {
        guard playerPeriodicTimeObserver == nil else { return }
        
        playerPeriodicTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(
                seconds: 0.01,
                preferredTimescale: CMTimeScale(NSEC_PER_SEC)
            ),
            queue: .main,
            using: { [weak self] time in
                guard let self else { return }
                if time.isValid && time >= .zero {
                    if !self.startedPlaying {
                        self.startedPlaying = true
                    }
                    
                    self.timeObserverHandler?(time)
                }
            }
        )
    }
    
    private func removePlayerTimeObserver() {
        guard let playerPeriodicTimeObserver = playerPeriodicTimeObserver else { return }
        player.removeTimeObserver(playerPeriodicTimeObserver)
        self.playerPeriodicTimeObserver = nil
    }
    
    @objc private func handlePlayerItemDidPlayToEndNotification() {
        if loop || shouldPlay {
            seekTo(time: .zero)
            play()
        }
    }
}
