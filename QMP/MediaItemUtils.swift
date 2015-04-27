//
//  MediaItemUtils.swift
//  QMP
//
//  Created by FAHAD RIAZ on 4/26/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

struct MediaItemUtils {
    
    static let zeroTime:String = "0:00"

    static func getTimeRepresentation(timevalue:NSTimeInterval) -> String {
        if(timevalue == Double.NaN || timevalue < 1) {
            return self.zeroTime
        }
        
        var min:String = (Int(timevalue)/60).description
        var secValue = Int(timevalue)%60
        var sec:String!
        if(secValue < 10) {
            sec = "0" + secValue.description
        } else {
            sec = secValue.description
        }
        
        return min + ":" + sec

    }
}
