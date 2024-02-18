//
//  ResultModel.swift
//  SwiftStudentChallenge2024
//
//  Created by Roman Rakhlin on 2/18/24.
//

import Foundation

struct ResultModel: Identifiable {
    let id: Int
    let video: URL
    let thumbnail: URL
    
    init(id: Int, video: URL, thumbnail: URL) {
        self.id = id
        self.video = video
        self.thumbnail = thumbnail
    }
}

extension ResultModel {
    init(object: ResultObject) {
        self.id = object.id
        
        let videoURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        let thumbnailURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        
        try? object.video.write(to: videoURL, options: [.atomic])
        try? object.thumbnail.write(to: thumbnailURL, options: [.atomic])
        
        self.video = videoURL
        self.thumbnail = thumbnailURL
    }
}
