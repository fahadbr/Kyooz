//
//  PlayCountIterator.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/16/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import MediaPlayer
import UIKit

final class PlayCountIterator : NSObject {
    
    private static let directory = TempDataDAO.tempDirectory.URLByAppendingPathComponent("storedPlayCounts.archive").path!
    private static let timeIntervalInSeconds:Double = 20 * 60 //20 minutes
    
    private static let backgroundQueue:NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.qualityOfService = NSQualityOfService.Background
        queue.maxConcurrentOperationCount = 1
        queue.name = "Kyooz.PlayCountIteratorBackgroundQueue"
        return queue
    }()
    
    private var lastOperationTime:CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    private var backgroundTaskIdentifier:UIBackgroundTaskIdentifier?
    private var playCountIteratorOperation:PlayCountIteratorOperation?
    
    override init() {
        super.init()
        registerForAppNotifications()
    }
    
    deinit {
        unregisterForAppNotifications()
    }
    
    private func performOperationIfTimeWindowPassed() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        if (currentTime - lastOperationTime) < -1 || playCountIteratorOperation != nil {
            return
        }
        lastOperationTime = currentTime
        
        guard let oldPlayCounts = getPersistedPlayCounts() else {
            Logger.debug("no play counts to compare to")
            return
        }
        
        let op = PlayCountIteratorOperation(oldPlayCounts: oldPlayCounts)
        op.completionBlock = {
            self.playcountOpDidComplete(op)
        }
        playCountIteratorOperation = op
        PlayCountIterator.backgroundQueue.addOperation(op)
    }
    
    private func getPersistedPlayCounts() -> [NSNumber:Int]? {
        if !NSFileManager.defaultManager().fileExistsAtPath(PlayCountIterator.directory) {
            PlayCountIterator.backgroundQueue.addOperationWithBlock() {
                self.createInitialPlaycounts()
            }
            return nil
        }
        
        if let playCounts = NSKeyedUnarchiver.unarchiveObjectWithFile(PlayCountIterator.directory) as? [NSNumber:Int] {
            return playCounts
        }
        return nil
    }
    
    private func createInitialPlaycounts() {
        guard let items = MPMediaQuery.songsQuery().items else {
            return
        }

        Logger.debug("creating initial playcounts")
        
        var newPlayCounts = [NSNumber:Int]()
        for item in items {
            newPlayCounts[NSNumber(unsignedLongLong: item.persistentID)] = item.playCount
        }
        
        persistPlayCounts(newPlayCounts)
    }
    
    private func persistPlayCounts(playCounts:[NSNumber:Int]) {
        if !NSKeyedArchiver.archiveRootObject(playCounts as NSDictionary, toFile: PlayCountIterator.directory) {
            Logger.error("couldn't write the new playcounts successfully")
        }
    }
    
    private func playcountOpDidComplete(operation:PlayCountIteratorOperation) {
        persistPlayCounts(operation.newPlayCounts)
        playCountIteratorOperation = nil
        if backgroundTaskIdentifier != nil {
            TempDataDAO.instance.persistLastFmScrobbleCache()
            endBackgroundTask()
        } else {
            LastFmScrobbler.instance.submitCachedScrobbles()
        }
    }
    
    private func endBackgroundTask() {
        if let bgTask = backgroundTaskIdentifier {
            UIApplication.sharedApplication().endBackgroundTask(bgTask)
            backgroundTaskIdentifier = nil
        }
    }
    
    
    func handleApplicationWillEnterForeground(notification: NSNotification) {
        endBackgroundTask()
//        PlayCountIterator.backgroundQueue.addOperationWithBlock() {
            self.performOperationIfTimeWindowPassed()
//        }
    }
    
    func handleApplicationDidEnterBackground(notification: NSNotification) {
        if playCountIteratorOperation == nil { return }
        
        Logger.debug("starting background task for playCountIterator")
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithName("playCountIteratorOperation") { () -> Void in
            Logger.debug("canceling play count task")
            PlayCountIterator.backgroundQueue.cancelAllOperations()
        }
    }
    
    func handleApplicationWillTerminateNotification(notification:NSNotification) {
        PlayCountIterator.backgroundQueue.cancelAllOperations()
    }
    
    private func registerForAppNotifications() {
        let app = UIApplication.sharedApplication()
        let n = NSNotificationCenter.defaultCenter()
        n.addObserver(self, selector: "handleApplicationWillEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: app)
        n.addObserver(self, selector: "handleApplicationWillTerminateNotification:", name: UIApplicationWillTerminateNotification, object: app)
        n.addObserver(self, selector: "handleApplicationDidEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: app)
    }
    
    private func unregisterForAppNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
