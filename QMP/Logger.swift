//
//  Logger.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/3/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

final class Logger {
    
    static let loggerQueue = dispatch_queue_create("com.riaz.fahad.Kyooz.Logger", DISPATCH_QUEUE_SERIAL)
    
    private static let debugEnabled = true
    
    
    private static var threadName:String {
        return NSOperationQueue.currentQueue()?.name ?? "null"
    }
    
    static func debug(@autoclosure(escaping) messageBlock: ()->String) {
        if !debugEnabled { return }
        
        let date = NSDate()
        let threadId = threadName
        dispatch_async(loggerQueue) {
            print("\(date.description) [DEBUG] [\(threadId)]:  \(messageBlock())")
        }
    }
    
    static func error(message:String) {
        let date = NSDate()
        let threadId = threadName
        dispatch_async(loggerQueue) {
            print("\(date.description) [ERROR] [\(threadId)]:  \(message)")
        }
    }
    
}