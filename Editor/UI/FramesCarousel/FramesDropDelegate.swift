//
//  File.swift
//  
//
//  Created by Roman Rakhlin on 2/6/24.
//

import SwiftUI

//struct FramesDropDelegate: DropDelegate {
//
//    let item: FrameItem
//    @Binding var items: [FrameItem]
//    @Binding var draggedItem: FrameItem?
//
//    func performDrop(info: DropInfo) -> Bool {
//        return true
//    }
//
//    func dropEntered(info: DropInfo) {
//        guard let draggedItem = self.draggedItem else {
//            return
//        }
//
//        if draggedItem != item {
//            let from = items.firstIndex(of: draggedItem)!
//            let to = items.firstIndex(of: item)!
//            withAnimation(.default) {
//                self.items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
//            }
//        }
//    }
//}
