//
//  CameraResultView.swift
//
//
//  Created by Roman Rakhlin on 2/8/24.
//

import SwiftUI
import AVKit

public struct CameraResultView: View {
    
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    
    @ObservedObject var cameraViewModel: CameraViewModel
    
    @State private var playerView: VideoPlayerView?
    
    private var url: URL? { cameraViewModel.previewURL }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let image = cameraViewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if let playerView {
                    playerView
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onChange(of: url) { _ in
                configure()
            }
        }
        .onAppear {
            playerViewModel.showProgress = false
            playerViewModel.isPauseDisabled = true
            configure()
        }
    }
    
    private func configure() {
        guard let url else { return }
        
        if url.isVideo {
            playerView = VideoPlayerView(viewModel: playerViewModel)
            cameraViewModel.selectedAsset = AVAsset(url: url)
            playerViewModel.playerItem = AVPlayerItem(url: url)
        } else {
            cameraViewModel.selectedImage = UIImage(contentsOfFile: url.path)
        }
    }
}
