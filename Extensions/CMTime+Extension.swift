//
//  CMTime+Extension.swift
//
//
//  Created by Roman Rakhlin on 2/6/24.
//

import CoreMedia

extension CMTime {
    init(seconds: TimeInterval) {
        self = CMTimeMakeWithSeconds(seconds, preferredTimescale: 600) // Apple recommended preferredTimescale is 600
    }
}
