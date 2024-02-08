//
//  VideoCompositor.swift
//  
//
//  Created by Roman Rakhlin on 2/8/24.
//

import AVFoundation

enum VideoCompositor {}

extension VideoCompositor {
    enum Error: Swift.Error {
        case numberOfFramesDoesNotMatchNumberOfImages
        case noImagesSpecified
        case noSuchAudioFile
        case pixelBufferCreationFailed
        case noVideoTracksFound
    }
}
