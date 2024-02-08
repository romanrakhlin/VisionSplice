//
//  FramesCarouselItemView.swift
//
//
//  Created by Roman Rakhlin on 2/8/24.
//

import SwiftUI

struct FramesCarouselItemView: View {
    
    var frame: FrameItem
//    var thumbnailGeneration: (() async throws -> UIImage)?
    
    @State var thumbnail: Image?
    
    private let size = CGSize(
        width: UIDevice.current.userInterfaceIdiom == .pad ? 120 : 60,
        height: UIDevice.current.userInterfaceIdiom == .pad ? 160 : 80
    )
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Constants.secondaryColor)
                .frame(width: size.width, height: size.height)
            
            if let thumbnail {
                thumbnail
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            }
            
            if frame is FrameEmptyItem {
                Image(systemName: "plus")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Constants.primaryColor)
            }
            
//                        Text("kfjgnj")
//                            .font(.system(size: 14, weight: .bold, design: .rounded))
//                            .foregroundColor(.white)
        }
        .cornerRadius(10)
        .shadow(radius: 4)
        .onAppear {
            Task {
                let generatedThumbnail = try await frame.generateThumbnail()
                
                Task { @MainActor in
                    thumbnail = Image(uiImage: generatedThumbnail)
                }
            }
        }
    }
}
