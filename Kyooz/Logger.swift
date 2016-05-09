//
//  Logger.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/3/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

final class Logger {
    
    static let errorLogKey = "errorLogKey"
    static let loggerQueue = dispatch_queue_create("com.riaz.fahad.Kyooz.Logger", DISPATCH_QUEUE_SERIAL)
    
    static var errorLogString = TempDataDAO.instance.getPersistentValue(key: errorLogKey) as? String ?? "" {
        didSet {
            TempDataDAO.instance.addPersistentValue(key: errorLogKey, value: errorLogString)
        }
    }
    
    private static let debugEnabled = true
    
    
    private static var threadName:String {
        return NSOperationQueue.currentQueue()?.name ?? "null"
    }
    
    static func initialize() {
        
    }
    
    static func debug(@autoclosure messageBlock: ()->String) {
        if !debugEnabled { return }
        
        let date = NSDate()
        let threadId = threadName
        let message = messageBlock()
        dispatch_async(loggerQueue) {
            print("\(date.description) [DEBUG] [\(threadId)]:  \(message)")
        }
    }
    
    static func error(message:String) {
        let date = NSDate()
        let threadId = threadName
        dispatch_async(loggerQueue) {
            let message = "\(date.description) [ERROR] [\(threadId)]:  \(message)"
            errorLogString.appendContentsOf("\n\(message)")
            print(message)
        }
    }
    
}