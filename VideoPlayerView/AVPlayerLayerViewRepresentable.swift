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

    func makeUIView(context: Context) -> AVPlayerLayerView {
        let playerLayerView = AVPlayerLayerView()
        
        playerLayerView.avPlayerLayer?.videoGravity = videoGravity
        playerLayerView.avPlayerLayer?.player = player
        
        return playerLayerView
    }

    func updateUIView(_ uiView: AVPlayerLayerView, context: Context) {
        uiView.avPlayerLayer?.videoGravity = videoGravity
        uiView.avPlayerLayer?.player = player
    }
}
