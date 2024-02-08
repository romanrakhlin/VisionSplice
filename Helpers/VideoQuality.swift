//
//  File.swift
//  
//
//  Created by Roman Rakhlin on 2/6/24.
//

import AVFoundation

enum VideoQuality {
    case highest
    case medium
    case low
    case fullHD
    case hd

    var presetName: String {
        switch self {
        case .highest:
            return AVAssetExportPresetHighestQuality
        case .medium:
            return AVAssetExportPresetMediumQuality
        case .low:
            return AVAssetExportPresetMediumQuality
        case .fullHD:
            return AVAssetExportPreset1920x1080
        case .hd:
            return AVAssetExportPreset1280x720
        }
    }
}
