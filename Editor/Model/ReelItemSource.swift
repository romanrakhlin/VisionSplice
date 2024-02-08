//
//  FrameItemSource.swift
//
//
//  Created by Roman Rakhlin on 2/6/24.
//

import AVFoundation
import UIKit

protocol FrameItemSource {}

extension UIImage: FrameItemSource {}

extension AVAsset: FrameItemSource {}
