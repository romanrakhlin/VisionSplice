//
//  ShareViewModel.swift
//
//
//  Created by Roman Rakhlin on 2/16/24.
//

import SwiftUI
import AVFoundation
import Photos

final class ShareViewModel: ObservableObject {
    
    @Published var playerItem: AVPlayerItem?
    
    private var url: URL? { (playerItem?.asset as? AVURLAsset)?.url }
    
    func share() -> Bool {
        guard let url else { return false }
        
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .authorized {
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }
            return true
        } else {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { _ in }
            return false
        }
    }
}
