//
//  FramesCarouselView.swift
//
//
//  Created by Roman Rakhlin on 2/8/24.
//

import SwiftUI

struct FramesCarouselView: View {
    
    @ObservedObject var cameraViewModel: CameraViewModel
    @ObservedObject var videoModel: VideoViewModel
    
    @State var draggedFrame: (any FrameItem)?
    
    @Binding var selectedFrame: (any FrameItem)?
    @Binding var isCreatePresented: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(videoModel.items, id: \.id) { item in
                    ZStack {
                        FramesCarouselItemView(frame: item)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .inset(by: 1)
                                    .stroke(.white, lineWidth: selectedFrame?.id == item.id ? 4 : 0)
                            )
                        
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 30, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(selectedFrame?.id == item.id ? 1 : 0)
                    }
                    .onTapGesture {
                        withAnimation {
                            Haptics.play(.light)
                            
                            selectedFrame = selectedFrame?.id == item.id ? nil : item
                        }
                    }
                    .onDrag({
                        selectedFrame = nil
                        draggedFrame = item
                        let nsItem = NSItemProvider(object: NSString(string: item.id.uuidString))
                        nsItem.suggestedName = item.id.uuidString
                        return nsItem
                    })
                    .onDrop(of: [.text], delegate: FramesDropDelegate(frame: item, videoModel: videoModel, draggedFrame: $draggedFrame))
                }
                
                FramesCarouselItemView(isEmptyItem: true)
                    .onTapGesture {
                        Haptics.play(.medium)
                        
                        selectedFrame = nil
                        isCreatePresented.toggle()
                    }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
        .padding(.bottom)
    }
}
