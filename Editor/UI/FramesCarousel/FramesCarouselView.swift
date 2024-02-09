//
//  FramesCarouselView.swift
//
//
//  Created by Roman Rakhlin on 2/8/24.
//

import SwiftUI

struct FramesCarouselView: View {
    
    @ObservedObject var videoModel: VideoModel
    
    @Binding var selectedFrame: FrameItem?
    @Binding var draggedItem: FrameItem?
    
    @Binding var isActionsSheetPresented: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(Array(videoModel.items.enumerated()), id: \.offset) { index, item in
                    FramesCarouselItemView(frame: item)
                        .onTapGesture {
                            selectedFrame = item
                            isActionsSheetPresented.toggle()
                        }
//                    .onDrag({
//                        draggedItem = frame
//                        return NSItemProvider(item: nil, typeIdentifier: frame)
//                    })
//                    .onDrop(of: [.text], delegate: FramesDropDelegate(item: frame, items: $videoModel.items, draggedItem: $draggedItem))
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
        .padding(.bottom)
    }
}
