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
    
    private static let directory = TempDataDAO.tempDirectory.appendingPathComponent("storedPlayCounts.archive").path
    private static let timeIntervalInSeconds:Double = 20 * 60 //20 minutes
    
    private static let backgroundQueue:OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = QualityOfService.background
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
        DispatchQueue.main.asyncAfter(deadline: KyoozUtils.getDispatchTimeForSeconds(3)) {
            PlayCountIterator.backgroundQueue.addOperation() {
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
    
    private func performOperationWithTime(_ currentTime:CFAbsoluteTime, operationCompletionBlock:(()->Void)? = nil) {
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
        if !FileManager.default.fileExists(atPath: PlayCountIterator.directory) {
            PlayCountIterator.backgroundQueue.addOperation() {
                self.createInitialPlaycounts()
            }
            return nil
        }
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: PlayCountIterator.directory) as? NSDictionary
    }
    
    private func createInitialPlaycounts() {
        guard let items = MPMediaQuery.songs().items else {
            return
        }

        Logger.debug("creating initial playcounts")
        
        let newPlayCounts = NSMutableDictionary()
        for item in items {
            newPlayCounts.setObject(NSNumber(value: item.playCount), forKey: NSNumber(value: item.persistentID))
        }
        
        persistPlayCounts(newPlayCounts)
    }
    
    private func persistPlayCounts(_ playCounts:NSDictionary) {
        if !NSKeyedArchiver.archiveRootObject(playCounts, toFile: PlayCountIterator.directory) {
            Logger.error("couldn't write the new playcounts successfully")
        }
    }
    
    private func playcountOpDidComplete(_ newPlayCounts:NSDictionary) {
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
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = UIBackgroundTaskInvalid
        }
    }
    
    func performBackgroundIteration(_ completionHandler: (UIBackgroundFetchResult) -> Void) {
        guard playCountIteratorOperation == nil else {
            Logger.debug("already performing background fetch")
            completionHandler(.noData)
            return
        }
        
        performingBackgroundFetch = true
        performOperationWithTime(CFAbsoluteTimeGetCurrent()) {
            LastFmScrobbler.instance.submitCachedScrobbles() {
                Logger.debug("done with background iteration")
                self.performingBackgroundFetch = false
                completionHandler(ApplicationDefaults.audioQueuePlayer.musicIsPlaying ? .newData : .noData)
            }
        }
    }
    
    //MARK: - App Notification Handlers
    
    func handleApplicationWillEnterForeground(_ notification: Notification) {
        endBackgroundTask()
        PlayCountIterator.backgroundQueue.addOperation() {
            self.performOperationIfTimeWindowPassed()
        }
    }
    
    func handleApplicationDidEnterBackground(_ notification: Notification) {
        if playCountIteratorOperation == nil { return }
        
        endBackgroundTask()
        
        Logger.debug("starting background task for playCountIterator")
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "playCountIteratorOperation") { () -> Void in
            Logger.debug("canceling play count task")
            PlayCountIterator.backgroundQueue.cancelAllOperations()
        }
        
        if backgroundTaskIdentifier == UIBackgroundTaskInvalid {
            Logger.debug("was not able to start background task")
        }
    }
    
    func handleApplicationWillTerminateNotification(_ notification:Notification) {
        PlayCountIterator.backgroundQueue.cancelAllOperations()
    }
    
    private func registerForAppNotifications() {
        let app = UIApplication.shared
        let n = NotificationCenter.default
        n.addObserver(self, selector: #selector(PlayCountIterator.handleApplicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: app)
        n.addObserver(self, selector: #selector(PlayCountIterator.handleApplicationWillTerminateNotification(_:)), name: NSNotification.Name.UIApplicationWillTerminate, object: app)
        n.addObserver(self, selector: #selector(PlayCountIterator.handleApplicationDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: app)
    }
    
    private func unregisterForAppNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}
