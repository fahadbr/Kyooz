//
//  Logger.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/3/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

class Logger {
    
    static let loggerQueue = dispatch_queue_create("com.riaz.fahad.Kyooz.Logger", DISPATCH_QUEUE_SERIAL)
    
    class func debug(message:String) {
        let date = NSDate()
        let threadId = NSThread.currentThread().isMainThread ? "main" : NSThread.currentThread().description
        dispatch_async(loggerQueue) {
            print("\(date.description) [DEBUG] [\(threadId)]:  \(message)")
        }
    }
    
    class func error(message:String) {
        let date = NSDate()
        let threadId = NSThread.currentThread().isMainThread ? "main" : NSThread.currentThread().description
        dispatch_async(loggerQueue) {
            print("\(date.description) [ERROR] [\(threadId)]:  \(message)")
        }
    }
    
}