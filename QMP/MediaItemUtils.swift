//
//  MediaItemUtils.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/26/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

struct MediaItemUtils {
    
    static let zeroTime:String = "0:00"

    static func getTimeRepresentation(timevalue:Float) -> String {
        if(timevalue == Float.NaN || timevalue == Float.infinity || timevalue < 1) {
            return self.zeroTime
        }
               
        var min:String = "\(Int(timevalue)/60)"
        var secValue = Int(timevalue)%60
        var sec = secValue < 10 ? "0\(secValue)" : "\(secValue)"
        
        return "\(min):\(sec)"
    }
}
