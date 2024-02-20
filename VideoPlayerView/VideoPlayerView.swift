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
    
    private var asset: AVAsset? { viewModel.asset }
    
    public var body: some View {
        ZStack {
            AVPlayerLayerViewRepresentable(
                player: $viewModel.player,
                videoGravity: $viewModel.videoGravity,
                isMuted: $viewModel.isMuted
            )
            .onTapGesture {
                guard viewModel.assetState == .ready, !viewModel.isPauseDisabled else { return }
                    
                switch viewModel.playbackState {
                case .stopped, .paused:
                    viewModel.play()
                case .playing:
                    viewModel.pause()
                }
            }
                
            Rectangle()
                .fill(.clear)
                .background {
                    if viewModel.assetState == .loading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else if viewModel.assetState == .ready && !viewModel.isPauseDisabled {
                        if viewModel.playbackState == .playing {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(Constants.primaryColor)
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(Constants.primaryColor)
                        }
                    }
                }
            
            if viewModel.showProgress {
                VStack {
                    Spacer()
                    
                    ProgressView(value: viewModel.videoProgress, total: 1)
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
            viewModel.updatePlaybackProgress(withTime: time)
        }
    }
}
