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
                
            if viewModel.assetState == .loading {
                ProgressView()
                    .progressViewStyle(.circular)
            }
            
            if viewModel.showProgress {
                VStack {
                    Spacer()
                    
                    ProgressView(value: viewModel.videoProgress, total: 1)
                        .accentColor(.white)
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
