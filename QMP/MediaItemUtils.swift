//
//  MediaItemUtils.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/26/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

struct MediaItemUtils {
    
    static let zeroTime:String = "0:00"
    static let yearDateFormatter:NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
    
    static func getTimeRepresentation(timevalue:NSTimeInterval) -> String {
        return getTimeRepresentation(Float(timevalue))
    }

    static func getTimeRepresentation(timevalue:Float) -> String {
        let values = getMinuteAndSecondValues(timevalue)
        
        if values.minutes == 0 && values.seconds == 0 {
            return zeroTime
        }
        let secValue = values.seconds
        let sec = secValue < 10 ? "0\(secValue)" : "\(secValue)"
        
        return "\(values.minutes):\(sec)"
    }
    
    static func getLongTimeRepresentation(timevalue:NSTimeInterval) -> String? {
        let values = getMinuteAndSecondValues(Float(timevalue))
        
        if values.minutes == 0 && values.seconds == 0{
            return nil
        }
        
        var times = [String]()
        if values.minutes != 0 {
            times.append("\(values.minutes) Minutes")
        }
        if values.seconds != 0 {
            times.append("\(values.seconds) Seconds")
        }
        return times.joinWithSeparator("  ")
    }
    
    static func getMinuteAndSecondValues(timevalue:Float) -> (minutes:Int, seconds:Int){
        if(timevalue == Float.NaN || timevalue == Float.infinity || timevalue < 1) {
            return (0, 0)
        }
        
        //not sure why the above checks dont work for NaN but this one does
        if(!timevalue.isNormal) {
            return (0, 0)
        }
        
        let min = Int(timevalue)/60
        let secValue = Int(timevalue)%60
        return (min, secValue)
    }
    
    static func getReleaseDateString(mediaItem:MPMediaItem) -> String? {
        if let releaseDate = mediaItem.valueForKey("year") as? NSNumber where !releaseDate.isEqualToNumber(NSNumber(integer: 0)) {
            return "\(releaseDate)"
        }
        return nil
    }
}
