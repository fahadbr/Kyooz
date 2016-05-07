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
    
    private var lastOperationTime:CFAbsoluteTime = 0
    private var backgroundTaskIdentifier:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    private var playCountIteratorOperation:PlayCountIteratorOperation?
    private var performingBackgroundFetch = false
    
    override init() {
        super.init()
        registerForAppNotifications()
        BackgroundFetchController.instance.playCountIterator = self
        dispatch_after(KyoozUtils.getDispatchTimeForSeconds(3), dispatch_get_main_queue()) {
            PlayCountIterator.backgroundQueue.addOperationWithBlock() {
                self.performOperationIfTimeWindowPassed()
            }
        }
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
    
    private func performOperationWithTime(currentTime:CFAbsoluteTime, operationCompletionBlock:(()->Void)? = nil) {
        lastOperationTime = currentTime
        guard let oldPlayCounts = getPersistedPlayCounts() else {
            Logger.debug("no play counts to compare to")
            operationCompletionBlock?()
            return
        }
        
        let op = PlayCountIteratorOperation(oldPlayCounts: oldPlayCounts, playCountCompletionBlock: self.playcountOpDidComplete)
        op.completionBlock = operationCompletionBlock
        playCountIteratorOperation = op
        PlayCountIterator.backgroundQueue.addOperation(op)

    }
    
    private func getPersistedPlayCounts() -> NSDictionary? {
        if !NSFileManager.defaultManager().fileExistsAtPath(PlayCountIterator.directory) {
            PlayCountIterator.backgroundQueue.addOperationWithBlock() {
                self.createInitialPlaycounts()
            }
            return nil
        }
        
        return NSKeyedUnarchiver.unarchiveObjectWithFile(PlayCountIterator.directory) as? NSDictionary
    }
    
    private func createInitialPlaycounts() {
        guard let items = MPMediaQuery.songsQuery().items else {
            return
        }

        Logger.debug("creating initial playcounts")
        
        let newPlayCounts = NSMutableDictionary()
        for item in items {
            newPlayCounts.setObject(NSNumber(integer: item.playCount), forKey: NSNumber(unsignedLongLong: item.persistentID))
        }
        
        persistPlayCounts(newPlayCounts)
    }
    
    private func persistPlayCounts(playCounts:NSDictionary) {
        if !NSKeyedArchiver.archiveRootObject(playCounts, toFile: PlayCountIterator.directory) {
            Logger.error("couldn't write the new playcounts successfully")
        }
    }
    
    private func playcountOpDidComplete(newPlayCounts:NSDictionary) {
        persistPlayCounts(newPlayCounts)
        playCountIteratorOperation = nil
        if backgroundTaskIdentifier != UIBackgroundTaskInvalid  {
            LastFmScrobbler.instance.submitCachedScrobbles() {
                self.endBackgroundTask()
            }
        } else if !performingBackgroundFetch {
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
        performOperationWithTime(CFAbsoluteTimeGetCurrent()) {
            LastFmScrobbler.instance.submitCachedScrobbles() {
                Logger.debug("done with background iteration")
                self.performingBackgroundFetch = false
                completionHandler(ApplicationDefaults.audioQueuePlayer.musicIsPlaying ? .NewData : .NoData)
            }
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
        n.addObserver(self, selector: #selector(PlayCountIterator.handleApplicationWillEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: app)
        n.addObserver(self, selector: #selector(PlayCountIterator.handleApplicationWillTerminateNotification(_:)), name: UIApplicationWillTerminateNotification, object: app)
        n.addObserver(self, selector: #selector(PlayCountIterator.handleApplicationDidEnterBackground(_:)), name: UIApplicationDidEnterBackgroundNotification, object: app)
    }
    
    private func unregisterForAppNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
