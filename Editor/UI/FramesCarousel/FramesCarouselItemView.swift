//
//  FramesCarouselItemView.swift
//
//
//  Created by Roman Rakhlin on 2/8/24.
//

import SwiftUI

struct FramesCarouselItemView: View {
    
    var thumbnailGeneration: () async throws -> UIImage
    
    @State var thumbnail: Image?
    
    private let frame = CGSize(
        width: UIDevice.current.userInterfaceIdiom == .pad ? 120 : 60,
        height: UIDevice.current.userInterfaceIdiom == .pad ? 160 : 80
    )
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Constants.secondaryColor)
                .frame(width: frame.width, height: frame.height)
            
            if let thumbnail {
                thumbnail
                    .resizable()
                    .scaledToFill()
                    .frame(width: frame.width, height: frame.height)
                    .clipped()
            }
            
//                        Text("kfjgnj")
//                            .font(.system(size: 14, weight: .bold, design: .rounded))
//                            .foregroundColor(.white)
        }
        .cornerRadius(10)
        .shadow(radius: 4)
        .onAppear {
            Task {
                let generatedThumbnail = try await thumbnailGeneration()
                
                Task { @MainActor in
                    thumbnail = Image(uiImage: generatedThumbnail)
                }
            }
        }
    }
}
