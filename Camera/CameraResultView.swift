//
//  CameraResultView.swift
//  CustomCameraApp
//
//  Created by Karen Mirakyan on 09.05.22.
//

import SwiftUI
import AVKit
import PhotosUI

public struct CameraResultView: View {
    
    let url: URL?
    
    private var isVideo: Bool {
        guard let url else { return false }
        
        return url.absoluteString.hasSuffix(".mov")
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let url {
                    if isVideo {
                        PlayerView(url: url)
                    } else if let uiImage = UIImage(contentsOfFile: url.path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
