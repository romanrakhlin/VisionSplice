//
//  VideoConfigiration.swift
//
//
//  Created by Roman Rakhlin on 2/6/24.
//

import Foundation

struct VideoConfigiration {
    /// The size of the rendered video
    let videoSize: CGSize

    /// Frames per second
    let fps: Int32

    /// Bits  per second
    let bitrate: Bitrate

    /// Video quality preset
    let quality: VideoQuality

    /// Output directory where all the temp files and the output will be stored. It must be already existent.
    let workingDirectoryURL: URL

    let exportDirectoryURL: URL
}

extension VideoConfigiration {
    static var export: Self {
        Self(
            videoSize: CGSize(width: 1920, height: 1080),
            fps: 30,
            bitrate: .reels,
            quality: .fullHD,
            workingDirectoryURL: FileManager.reelsWorkingDirectoryURL,
            exportDirectoryURL: FileManager.documentsDirectoryURL
        )
    }

    static var preview: Self {
        Self(
            videoSize: CGSize(width: 1280, height: 720),
            fps: 30,
            bitrate: .reels,
            quality: .fullHD,
            workingDirectoryURL: FileManager.reelsWorkingDirectoryURL,
            exportDirectoryURL: FileManager.reelsWorkingDirectoryURL
        )
    }
}

extension VideoConfigiration {
    func cleanupWorkingDirectory() {
        FileManager.default.deleteIfExists(at: workingDirectoryURL)
        _ = FileManager.default.lookupOrCreate(directoryAt: workingDirectoryURL)
    }
}
