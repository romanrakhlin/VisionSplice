import SwiftUI
import AVKit
import PhotosUI

public struct CameraResultView: View {
    
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    
    @Binding var url: URL?
    
    @State private var image: UIImage?
    @State private var playerView: VideoPlayerView?
    
    private var isVideo: Bool {
        guard let url else { return false }
        return url.absoluteString.hasSuffix(".mov") || url.absoluteString.hasSuffix(".MOV")
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let url {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else if let playerView {
                        playerView
                    } else {
                        Text("a")
                        ProgressView()
                    }
                } else {
                    Text("b")
                    ProgressView()
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onChange(of: url) { _ in
                configure()
            }
        }
        .onAppear {
            playerViewModel.isPauseDisabled = true
            configure()
        }
    }
    
    private func configure() {
        guard let url else { return }
        
        if isVideo {
            playerView = VideoPlayerView(model: playerViewModel)
            playerViewModel.playerItem = AVPlayerItem(url: url)
        } else {
            image = UIImage(contentsOfFile: url.path)
        }
    }
}
