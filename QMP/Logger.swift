//
//  Logger.swift
//  QMP
//
//  Created by FAHAD RIAZ on 5/3/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

class Logger {
    
    static let loggerQueue = dispatch_queue_create("com.riaz.fahad.QMP.Logger", DISPATCH_QUEUE_SERIAL)
    
    class func debug(message:String) {
        let date = NSDate()
        dispatch_async(loggerQueue) {
            println("\(date.description) [DEBUG]:  \(message)")
        }
    }
    
}