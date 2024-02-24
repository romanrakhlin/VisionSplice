//
//  VideoConfigiration.swift
//
//
//  Created by Roman Rakhlin on 2/6/24.
//

import SwiftUI

struct VideoConfigiration {
    
    /// The size of the rendered video
    let videoSize: VideoSize
    
    /// Frames per second
    let fps: Int32
    
    /// Bits  per second
    let bitrate: Float
    
    /// Video quality preset
    let quality: VideoQuality
    
    /// Output directory where all the temp files and the output will be stored. It must be already existent.
    let workingDirectoryURL: URL
    
    let exportDirectoryURL: URL
}

// MARK: - Video Size

extension VideoConfigiration {
    enum VideoSize {
        case lowPortrait
        case highPortrait
        case lowHorizontal
        case highHorizontal
        
        var size: CGSize {
            switch self {
            case .lowPortrait:
                return CGSize(width: 720, height: 1280)
            case .highPortrait:
                return CGSize(width: 1080, height: 1920)
            case .lowHorizontal:
                return CGSize(width: 1280, height: 720)
            case .highHorizontal:
                return CGSize(width: 1920, height: 1080)
            }
        }
    }
}

// MARK: - Create Merthod

extension VideoConfigiration {
    static func createConfiguration(isExport: Bool = false) -> Self {
        var orientation = Constants.orientation ?? .landscapeLeft
        var videoSize: VideoSize
        
        if isExport {
            if orientation == .portrait || orientation == .portraitUpsideDown {
                videoSize = .highPortrait
            } else {
                videoSize = .highHorizontal
            }
        } else {
            if orientation == .portrait || orientation == .portraitUpsideDown {
                videoSize = .lowPortrait
            } else {
                videoSize = .lowHorizontal
            }
        }
            
        return Self(
            videoSize: videoSize,
            fps: 30,
            bitrate: 4_000_000,
            quality: .fullHD,
            workingDirectoryURL: FileManager.videosWorkingDirectoryURL,
            exportDirectoryURL: FileManager.documentsDirectoryURL
        )
    }
}

extension VideoConfigiration {
    func cleanupWorkingDirectory() {
        FileManager.default.deleteIfExists(at: workingDirectoryURL)
        _ = FileManager.default.lookupOrCreate(directoryAt: workingDirectoryURL)
    }
}
