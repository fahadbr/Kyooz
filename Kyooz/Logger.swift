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
    
    static let dateFormatter:NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MM-dd-yy hh:mm:ss:SSS a"
        return formatter
    }()
	
    private static let debugEnabled = KyoozUtils.isDebugEnabled
    
    
    private static var threadName:String {
        var t =  NSOperationQueue.currentQueue()?.name ?? "null"
        t.removeSubstring("NSOperationQueue ")
        return t
    }
    
    static func debug(@autoclosure messageBlock: ()->String) {
        guard debugEnabled else { return }
        
        let date = NSDate()
        let threadId = threadName
        let message = messageBlock()
        dispatch_async(loggerQueue) {
            let dateString = dateFormatter.stringFromDate(date)
            print("\(dateString) DEBUG [\(threadId)]:  \(message)")
        }
    }
    
    static func error(message:String) {
        let date = NSDate()
        let threadId = threadName
        dispatch_async(loggerQueue) {
            let dateString = dateFormatter.stringFromDate(date)
            let message = "\(dateString) ERROR [\(threadId)]:  \(message)"
            print(message)
        }
    }
	
	
}