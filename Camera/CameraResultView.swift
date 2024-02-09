import SwiftUI
import AVKit
import PhotosUI

public struct CameraResultView: View {
    
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    
    @Binding var url: URL?
    @State private var playerView: VideoPlayerView?
    
    private var isVideo: Bool {
        guard let url else { return false }
        
        return url.absoluteString.hasSuffix(".mov")
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let url {
                    if let playerView {
                        playerView
                    } else if let uiImage = UIImage(contentsOfFile: url.path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Text("kjndf")
                    }
                } else {
                    ProgressView()
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .onAppear {
            playerViewModel.isPauseDisabled = true
        }
        .onChange(of: url) { _ in
            guard isVideo, let url else { return }
            playerView = VideoPlayerView(model: playerViewModel)
            playerViewModel.playerItem = AVPlayerItem(url: url)
        }
    }
}
