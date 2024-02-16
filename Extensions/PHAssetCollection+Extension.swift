//
//  File.swift
//  
//
//  Created by Roman Rakhlin on 2/16/24.
//

import Photos

extension PHAssetCollection {
    func addAssets(from assetChangeRequest: PHAssetChangeRequest) {
        let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: self)
        let enumeration: NSArray = [assetChangeRequest.placeholderForCreatedAsset!]
        assetCollectionChangeRequest?.addAssets(enumeration)
    }
}
