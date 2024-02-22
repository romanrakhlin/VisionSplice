//
//  Haptics.swift
//  
//
//  Created by Roman Rakhlin on 2/22/24.
//

import UIKit

final class Haptics {
    static func play(_ feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: feedbackStyle).impactOccurred()
    }
    
    static func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
    }
}
