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
    private var backgroundTaskIdentifier:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    private var playCountIteratorOperation:PlayCountIteratorOperation?
    private var performingBackgroundFetch = false
    
    override init() {
        super.init()
        registerForAppNotifications()
        BackgroundFetchController.instance.playCountIterator = self
    }
    
    deinit {
        unregisterForAppNotifications()
    }
    
    //MARK: - Class functions
    
    private func performOperationIfTimeWindowPassed() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        if (currentTime - lastOperationTime) < PlayCountIterator.timeIntervalInSeconds || playCountIteratorOperation != nil || !LastFmScrobbler.instance.validSessionObtained {
            return
        }
        performOperationWithTime(currentTime)
    }
    
    private func performOperationWithTime(currentTime:CFAbsoluteTime) {
        lastOperationTime = currentTime
        Logger.debug("performing operation at time \(currentTime)")
        guard let oldPlayCounts = getPersistedPlayCounts() else {
            Logger.debug("no play counts to compare to")
            return
        }
        
        let op = PlayCountIteratorOperation(oldPlayCounts: oldPlayCounts, playCountCompletionBlock: self.playcountOpDidComplete)
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
    
    private func playcountOpDidComplete(newPlayCounts:[NSNumber:Int]) {
        persistPlayCounts(newPlayCounts)
        playCountIteratorOperation = nil
        if performingBackgroundFetch {
            TempDataDAO.instance.persistLastFmScrobbleCache()
        } else if backgroundTaskIdentifier != UIBackgroundTaskInvalid  {
            TempDataDAO.instance.persistLastFmScrobbleCache()
            endBackgroundTask()
        } else {
            LastFmScrobbler.instance.submitCachedScrobbles()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskIdentifier != UIBackgroundTaskInvalid {
            UIApplication.sharedApplication().endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = UIBackgroundTaskInvalid
        }
    }
    
    func performBackgroundIteration(completionHandler: (UIBackgroundFetchResult) -> Void) {
        guard playCountIteratorOperation == nil else {
            Logger.debug("already performing background fetch")
            completionHandler(.NoData)
            return
        }
        
        performingBackgroundFetch = true
        performOperationWithTime(CFAbsoluteTimeGetCurrent())
        if let op = playCountIteratorOperation {
            op.completionBlock = {
                Logger.debug("done with background iteration")
                self.performingBackgroundFetch = false
                completionHandler(UIBackgroundFetchResult.NewData)
            }
        } else {
            performingBackgroundFetch = false
            completionHandler(.NoData)
        }
    }
    
    //MARK: - App Notification Handlers
    
    func handleApplicationWillEnterForeground(notification: NSNotification) {
        endBackgroundTask()
        PlayCountIterator.backgroundQueue.addOperationWithBlock() {
            self.performOperationIfTimeWindowPassed()
        }
    }
    
    func handleApplicationDidEnterBackground(notification: NSNotification) {
        if playCountIteratorOperation == nil { return }
        
        endBackgroundTask()
        
        Logger.debug("starting background task for playCountIterator")
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithName("playCountIteratorOperation") { () -> Void in
            Logger.debug("canceling play count task")
            PlayCountIterator.backgroundQueue.cancelAllOperations()
        }
        
        if backgroundTaskIdentifier == UIBackgroundTaskInvalid {
            Logger.debug("was not able to start background task")
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
