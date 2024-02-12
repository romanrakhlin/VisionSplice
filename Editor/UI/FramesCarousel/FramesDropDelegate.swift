//
//  File.swift
//  
//
//  Created by Roman Rakhlin on 2/6/24.
//

import SwiftUI

struct FramesDropDelegate: DropDelegate {

    let index: (any FrameItem)
    @ObservedObject var videoModel: VideoModel
    @Binding var draggedFrameIndex: (any FrameItem)?

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard videoModel.isReady, let draggedFrameIndex else { return }

        if
            draggedFrameIndex.id != index.id,
            let at = videoModel.items.firstIndex(where: { $0.id == draggedFrameIndex.id }),
            let to = videoModel.items.firstIndex(where: { $0.id == index.id })
        {
            videoModel.moveItem(at: at, to: to)
        }
    }
}
