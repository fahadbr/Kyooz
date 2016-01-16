//
//  PlayCountIterator.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/16/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

protocol KyoozAppDelegate : NSObjectProtocol {
    func registerForAppNotifications()
    func unregisterForAppNotifications()
}

extension KyoozAppDelegate where Self : NSObject {
    
    func handleApplicationWillEnterForeground(notification:NSNotification) {
        Logger.debug("calling kyooz app delegate method \(notification)")
    }
    
    func handleApplicationWillResignActive(notification:NSNotification) {
        Logger.debug("calling kyooz app delegate method \(notification)")
    }
    
    func handleApplicationWillTerminateNotification(notification:NSNotification) {
        Logger.debug("calling kyooz app delegate method \(notification)")
    }
    
    
    func registerForAppNotifications() {
        let app = UIApplication.sharedApplication()
        let n = NSNotificationCenter.defaultCenter()
        n.addObserver(self, selector: "handleApplicationWillEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: app)
        n.addObserver(self, selector: "handleApplicationWillResignActive:", name: UIApplicationWillResignActiveNotification, object: app)
        n.addObserver(self, selector: "handleApplicationWillTerminateNotification:", name: UIApplicationWillTerminateNotification, object: app)
    }
    
    func unregisterForAppNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}

final class PlayCountIterator : NSObject, KyoozAppDelegate {
    
    private static let directory = TempDataDAO.tempDirectory.URLByAppendingPathComponent("storedPlayCounts.txt").path!
    private static let timeIntervalInSeconds:Double = 20 * 60 //20 minutes
    
    private static let backgroundQueue:NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.qualityOfService = NSQualityOfService.Background
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    
    private var lastOperationTime:CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    
    override init() {
        super.init()
        registerForAppNotifications()
    }
    
    deinit {
        unregisterForAppNotifications()
    }
    
    func handleApplicationWillEnterForeground(notification: NSNotification) {
        performOperationIfTimeWindowPassed()
    }
    
    private func performOperationIfTimeWindowPassed() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        if (currentTime - lastOperationTime) < PlayCountIterator.timeIntervalInSeconds {
            return
        }
        lastOperationTime = currentTime
    }
    
    
}
