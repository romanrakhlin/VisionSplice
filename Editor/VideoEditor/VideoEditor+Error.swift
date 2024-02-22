//
//  VideoEditor+Error.swift
//  
//
//  Created by Roman Rakhlin on 2/22/24.
//

import Foundation

extension VideoEditor {
    enum ResizeError: Swift.Error {
        case missingVideoTrack
        case exportSessionInitializationFailed
        case failedScale
    }
}
