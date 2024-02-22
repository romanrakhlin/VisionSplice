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
    
    @ObservedObject var shareViewModel: ShareViewModel
    @Binding var isActionSheetPresented: Bool
    @Binding var isSharePresented: Bool
    @Binding var resultToDelete: ResultModel?
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                if let thumbnail {
                    ZStack {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                        
                        Rectangle()
                            .fill(.black.opacity(0.2))
                        
                        VStack {
                            HStack {
                                Button {
                                    Haptics.play(.light)
                                    resultToDelete = result
                                    isActionSheetPresented = true
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(14)
                                        .background(Color.black.opacity(0.4))
                                        .clipShape(Circle())
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                            
                            HStack {
                                Spacer()
                                
                                Text(result.durationString)
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                    }
                    .cornerRadius(24)
                    .onTapGesture {
                        Haptics.play(.rigid)
                        
                        guard !isActionSheetPresented else { return }
                        
                        shareViewModel.setPlayerItemWith(url: result.video)
                        isSharePresented = true
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Constants.secondaryColor)
                        
                        Image(systemName: "questionmark")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Project \(1)")
                            .foregroundColor(.white)
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                        
                        Text(result.dateString)
                            .foregroundColor(.white.opacity(0.3))
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                    }
                    
                    Spacer()
                }
                .padding(.top, 10)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            if let data = try? Data(contentsOf: result.thumbnail) {
                thumbnail = UIImage(data: data)
            }
        }
    }
}
