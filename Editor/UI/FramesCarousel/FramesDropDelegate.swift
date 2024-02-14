//
//  File.swift
//  
//
//  Created by Roman Rakhlin on 2/6/24.
//

import SwiftUI

struct FramesDropDelegate: DropDelegate {

    let frame: (any FrameItem)
    @ObservedObject var videoModel: VideoViewModel
    @Binding var draggedFrame: (any FrameItem)?

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard videoModel.isReady, let draggedFrame else { return }

        if
            draggedFrame.id != frame.id,
            let at = videoModel.indexForItem(draggedFrame),
            let to = videoModel.indexForItem(frame)
        {
            videoModel.moveItem(at: at, to: to)
        }
    }
}
