//
//  URL+Extension.swift
//  
//
//  Created by Roman Rakhlin on 2/16/24.
//

import Foundation

extension URL {
    var isVideo: Bool {
        return self.absoluteString.hasSuffix(".mov") || self.absoluteString.hasSuffix(".MOV")
    }
}
