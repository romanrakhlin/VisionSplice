//
//  FramesCarouselItemView.swift
//
//
//  Created by Roman Rakhlin on 2/8/24.
//

import SwiftUI

struct FramesCarouselItemView: View {
    
    var frame: (any FrameItem)?
    var isEmptyItem = false
    
    @State var thumbnail: Image?
    
    private let size = CGSize(
        width: UIDevice.current.userInterfaceIdiom == .pad ? 120 : 60,
        height: UIDevice.current.userInterfaceIdiom == .pad ? 160 : 80
    )
    
    var body: some View {
        ZStack {
            if isEmptyItem {
                Rectangle()
                    .fill(Constants.secondaryColor)
                    .frame(width: size.width, height: size.height)
                
                Image(systemName: "plus")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            } else {
                if let thumbnail, let duration = frame?.duration.seconds {
                    VStack {
                        thumbnail
                            .resizable()
                            .scaledToFill()
                            .frame(width: size.width, height: size.height)
                            .clipped()
                    }
                    .overlay {
                        Rectangle()
                            .fill(.linearGradient(Gradient(colors: [.clear, .black.opacity(0.8)]), startPoint: .top, endPoint: .bottom))
                            .padding(.top, 18)
                        
                        VStack {
                            Spacer()
                            
                            Text(String(format:"%.1f", duration))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .cornerRadius(10)
        .shadow(radius: 4)
        .onAppear { updateThumbnail() }
    }
    
    private func updateThumbnail() {
        Task {
            guard let frame else { return }
            
            let generatedThumbnail = try await frame.generateThumbnail()
            
            Task { @MainActor in
                thumbnail = Image(uiImage: generatedThumbnail)
            }
        }
    }
}
