//
//  ResultModel.swift
//  SwiftStudentChallenge2024
//
//  Created by Roman Rakhlin on 2/18/24.
//

import AVFoundation

struct ResultModel: Identifiable, Hashable {
    
    let id: String
    let video: URL
    let thumbnail: URL
    let date: Date
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var durationString: String {
        AVAsset(url: video).formattedDuration
    }
    
    var dateString: String {
        dateFormatter.string(from: date)
    }
    
    init(id: String, video: URL, thumbnail: URL, date: Date) {
        self.id = id
        self.video = video
        self.thumbnail = thumbnail
        self.date = date
    }
}

extension ResultModel {
    init(object: ResultObject) {
        self.id = object.id
        self.date = object.date
        
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
