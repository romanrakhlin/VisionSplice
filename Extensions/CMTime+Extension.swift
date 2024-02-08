//
//  CMTime+Extension.swift
//
//
//  Created by Roman Rakhlin on 2/6/24.
//

import CoreMedia

extension CMTime {
    
    public init(seconds: TimeInterval) {
        // Apple recommended preferredTimescale is 600
        self = CMTimeMakeWithSeconds(seconds, preferredTimescale: 600)
    }
}
