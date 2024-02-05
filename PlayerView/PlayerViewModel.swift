//
//  PlayerViewModel.swift
//  SwiftStudentChallenge2024
//
//  Created by Roman Rakhlin on 2/5/24.
//

import SwiftUI
import Combine
import AVFoundation

class PlayerViewModel: NSObject, ObservableObject {
    
    @Published var player = AVPlayer()
    @Published var shouldPlay = false
    @Published var startedPlaying = false
    @Published var loop = false
    
    var timeObserverHandler: ((CMTime) -> Void)?
    
    var playerItem: AVPlayerItem? {
        willSet {
            if playerItem != newValue {
                removeObservers(playerItem: playerItem)
                setupObservers(playerItem: newValue)
            }
        }
    }
    
    var asset: AVAsset? {
        playerItem?.asset
    }
    
    private var playerPeriodicTimeObserver: Any?
    private var subscriptions = Set<AnyCancellable>()
    
    convenience init(url: URL) {
        let asset = AVURLAsset(url: url)
        self.init(asset: asset)
    }
    
    convenience init(asset: AVAsset) {
        self.init(playerItem: AVPlayerItem(asset: asset))
    }
    
    convenience init(playerItem: AVPlayerItem) {
        self.init()
        
        self.player.isMuted = false
        self.player.allowsExternalPlayback = false
        self.player.actionAtItemEnd = .none
        self.player.automaticallyWaitsToMinimizeStalling = false
        
        self.playerItem = playerItem
        self.setupObservers(playerItem: playerItem)
    }
    
    deinit {
        removeObservers(playerItem: playerItem)
    }
    
    private func setupObservers(playerItem: AVPlayerItem?) {
        guard let playerItem = playerItem else { return }
        
        self.startedPlaying = false
        
        let asset = playerItem.asset
        let keys = ["duration", "playable", "tracks", "preferredTransform"]
        
        asset.loadValuesAsynchronously(forKeys: keys) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self, self.asset == asset else { return }
                self.player.replaceCurrentItem(with: playerItem)
            }
        }
        
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .sink { [weak self] _ in self?.handlePlayerItemDidPlayToEndNotification() }
            .store(in: &subscriptions)
        
        setupPlayerTimeObserver()
    }
    
    private func removeObservers(playerItem: AVPlayerItem?) {
        guard let playerItem = playerItem else { return }
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        removePlayerTimeObserver()
    }
    
    private func setupPlayerTimeObserver() {
        guard playerPeriodicTimeObserver == nil else { return }
        
        playerPeriodicTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] time in
            guard let self = self else { return }
            if time.isValid && time >= .zero {
                if !self.startedPlaying {
                    self.startedPlaying = true
                }
                self.timeObserverHandler?(time)
            }
        }
    }
    
    private func removePlayerTimeObserver() {
        if let observer = playerPeriodicTimeObserver {
            player.removeTimeObserver(observer)
            playerPeriodicTimeObserver = nil
        }
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
    
    @objc private func handlePlayerItemDidPlayToEndNotification() {
        if loop || shouldPlay {
            seekTo(time: .zero)
            play()
        }
    }
}
