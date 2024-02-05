//
//  AVPlayerView.swift
//  SwiftStudentChallenge2024
//
//  Created by Roman Rakhlin on 2/5/24.
//

import SwiftUI
import AVKit
import UIKit

struct AVPlayerView: UIViewControllerRepresentable {
    
    let playerItem: AVPlayerItem
    
    class Coordinator: AVPlayerViewController {
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        init() {
            super.init(nibName: nil, bundle: nil)
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            print("DNsjkfnsjdkf", player)
            player?.play()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            
            player?.pause()
        }
    }
    
    init(url: URL) {
        playerItem = AVPlayerItem(url: url)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller: AVPlayerViewController = context.coordinator
        
        controller.player = AVQueuePlayer(playerItem: playerItem)
//        controller.player.
        controller.showsPlaybackControls = false
        controller.videoGravity = AVLayerVideoGravity.resizeAspectFill
        controller.edgesForExtendedLayout = []

        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
