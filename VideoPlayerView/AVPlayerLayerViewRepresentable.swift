//
//  AVPlayerLayerViewRepresentable.swift
//
//
//  Created by Roman Rakhlin on 2/5/24.
//

import SwiftUI
import AVFoundation

struct AVPlayerLayerViewRepresentable: UIViewRepresentable {
    
    @Binding var player: AVPlayer
    @Binding var videoGravity: AVLayerVideoGravity
    @Binding var isMuted: Bool

    func makeUIView(context: Context) -> AVPlayerLayerView {
        let playerLayerView = AVPlayerLayerView()
        
        playerLayerView.avPlayerLayer?.videoGravity = videoGravity
        playerLayerView.avPlayerLayer?.player = player
        playerLayerView.avPlayerLayer?.player?.isMuted = isMuted
        
        return playerLayerView
    }

    func updateUIView(_ uiView: AVPlayerLayerView, context: Context) {
        uiView.avPlayerLayer?.videoGravity = videoGravity
        uiView.avPlayerLayer?.player = player
        uiView.avPlayerLayer?.player?.isMuted = isMuted
    }
}
