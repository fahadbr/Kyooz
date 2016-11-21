//
//  Logger.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/3/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

final class Logger {
    
    static let loggerQueue = DispatchQueue(label: "com.riaz.fahad.Kyooz.Logger")
    
    static let dateFormatter:DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yy hh:mm:ss:SSS a"
        return formatter
    }()
	
    private static let debugEnabled = KyoozUtils.isDebugEnabled
    
    
    private static var threadName:String {
        var t =  OperationQueue.current?.name ?? "null"
        t.removeSubstring("NSOperationQueue ")
        return t
    }
    
    static func debug(_ messageBlock: @autoclosure ()->String) {
        guard debugEnabled else { return }
        
        let date = Date()
        let threadId = threadName
        let message = messageBlock()
        //loggerQueue.async {
            let dateString = dateFormatter.string(from: date)
            print("\(dateString) DEBUG [\(threadId)]:  \(message)")
        //}
    }
    
    static func error(_ message:String) {
        let date = Date()
        let threadId = threadName
        loggerQueue.async {
            let dateString = dateFormatter.string(from: date)
            let message = "\(dateString) ERROR [\(threadId)]:  \(message)"
            print(message)
        }
    }
	
	
}
