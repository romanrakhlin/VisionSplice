//
//  ResulItemView.swift
//
//
//  Created by Roman Rakhlin on 2/18/24.
//

import SwiftUI

struct ResulItemView: View {
    
    let result: ResultModel
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                    
                    Rectangle()
                        .fill(.black.opacity(0.2))
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Constants.secondaryColor)
                        
                        Image(systemName: "questionmark")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .cornerRadius(14)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            if let data = try? Data(contentsOf: result.thumbnail) {
                thumbnail = UIImage(data: data)
            }
        }
    }
}
