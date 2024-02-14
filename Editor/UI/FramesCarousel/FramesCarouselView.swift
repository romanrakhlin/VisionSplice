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
    @Binding var isActionsSheetPresented: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(videoModel.items, id: \.id) { item in
                    FramesCarouselItemView(frame: item)
                        .onTapGesture {
                            selectedFrame = item
                            isActionsSheetPresented.toggle()
                        }
                    .onDrag({
                        draggedFrame = item
                        let nsItem = NSItemProvider(object: NSString(string: item.id.uuidString))
                        nsItem.suggestedName = item.id.uuidString
                        return nsItem
                    })
                    .onDrop(of: [.text], delegate: FramesDropDelegate(frame: item, videoModel: videoModel, draggedFrame: $draggedFrame))
                }
                
                FramesCarouselItemView(isEmptyItem: true)
                    .onTapGesture { 
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
