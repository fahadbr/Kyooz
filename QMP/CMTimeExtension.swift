//
//  CMTimeExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import AVFoundation

extension CMTime {
    
    static func fromSeconds(seconds:Float) -> CMTime {
        return CMTimeMakeWithSeconds(Double(seconds), Int32(1))
    }
    
    var seconds:Float {
        if(value == 0) {
            return 0.0
        }
        return Float(value)/Float(timescale)
    }
}