//
//  File.swift
//  
//
//  Created by Roman Rakhlin on 2/13/24.
//

import Foundation

extension VideoCompositor {
    enum Error: Swift.Error {
        case numberOfFramesDoesNotMatchNumberOfImages
        case noImagesSpecified
        case noSuchAudioFile
        case pixelBufferCreationFailed
        case noVideoTracksFound
    }
}
