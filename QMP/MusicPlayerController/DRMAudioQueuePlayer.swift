//
//  DRMAudioQueuePlayer.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/1/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer
import Foundation

final class DRMAudioQueuePlayer: NSObject, AudioQueuePlayer {
    static let instance = DRMAudioQueuePlayer()
    
    private let musicPlayer = ApplicationDefaults.defaultMusicPlayerController
    private let playbackStateManager = PlaybackStateManager.instance
    
    private var timer: NSTimer?
    private var backgroundTaskIdentifier:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    private var queueIsPersisted:Bool = true
    private let indexBeforeModificationKey = "indexBeforeModification"
    private let mediaPlayerAPIHelper = MediaPlayerAPIHelper()
    
    private var nowPlayingQueueContext:NowPlayingQueueContext {
        didSet {
            publishNotification(updateType: .QueueUpdate, sender: self)
        }
    }
    
    private var indexBeforeModification:Int = 0 {
        didSet {
            TempDataDAO.instance.addPersistentValue(key: indexBeforeModificationKey, value: NSNumber(integer: indexBeforeModification))
        }
    }
    
    override init() {
        if let nowPlayingQueueContext = TempDataDAO.instance.getPlaybackStateSnapshotFromTempStorage()?.nowPlayingQueueContext {
            self.nowPlayingQueueContext = nowPlayingQueueContext
        } else {
            Logger.error("couldnt get queue from temp storage. starting with empty queue")
            nowPlayingQueueContext = NowPlayingQueueContext(originalQueue: [AudioTrack]())
        }
        
        if let indexBeforeMod = TempDataDAO.instance.getPersistentValue(key: indexBeforeModificationKey) as? NSNumber {
            indexBeforeModification = indexBeforeMod.longValue
        }
        
        super.init()
        registerForMediaPlayerNotifications()
    }
    
    deinit {
        unregisterForMediaPlayerNotifications()
    }

    
    //MARK: AudioQueuePlayer - Properties
    
    var playbackStateSnapshot:PlaybackStateSnapshot {
        return PlaybackStateSnapshot(nowPlayingQueueContext: nowPlayingQueueContext, currentPlaybackTime: currentPlaybackTime, indexOfNowPlayingItem: indexOfNowPlayingItem)
    }
    
    var nowPlayingQueue:[AudioTrack] {
        return nowPlayingQueueContext.currentQueue
    }
    
    var nowPlayingItem:AudioTrack? {
        return musicPlayer.nowPlayingItem
    }
    var musicIsPlaying:Bool {
        return playbackStateManager.musicIsPlaying()
    }
    
    var currentPlaybackTime:Float {
        get {
            return Float(musicPlayer.currentPlaybackTime)
        } set {
            if(nowPlayingItem != nil) {
                musicPlayer.currentPlaybackTime = NSTimeInterval(newValue)
                publishNotification(updateType: .PlaybackStateUpdate, sender: self)
            }
        }
    }
    
    var indexOfNowPlayingItem:Int {
        get {
            return nowPlayingQueueContext.indexOfNowPlayingItem
        } set {
            nowPlayingQueueContext.indexOfNowPlayingItem = newValue
        }
    }
    
    var shuffleActive:Bool {
        get {
            return nowPlayingQueueContext.shuffleActive
        } set {
            nowPlayingQueueContext.setShuffleActive(newValue)
            persistToSystemQueue()
        }
    }
    
    var repeatMode:RepeatState {
        get {
            switch(musicPlayer.repeatMode) {
            case .None:
                return .Off
            case .All, .Default:
                return .All
            case .One:
                return .One
            }
        }
        set {
            Logger.debug("setting repeat mode \(newValue.rawValue)")
            switch(newValue) {
            case .Off:
                musicPlayer.repeatMode = .None
            case .One:
                musicPlayer.repeatMode = .One
            case .All:
                musicPlayer.repeatMode = .All
            }
        }
    }
    
    //MARK: AudioQueuePlayer - Functions
    
    func play() {
        persistQueueToAudioController(indexOfNowPlayingItem)
        musicPlayer.play()
    }
    
    func pause() {
        musicPlayer.pause()
        dispatch_after(KyoozUtils.getDispatchTimeForSeconds(0.25), dispatch_get_main_queue(), { () -> Void in
            self.persistQueueToAudioController(self.indexOfNowPlayingItem)
        })
    }
    
    func skipForwards() {
        if !persistQueueToAudioController(indexOfNowPlayingItem + 1) {
            musicPlayer.skipToNextItem()
        }
    }
    
    func skipBackwards() {
        if(currentPlaybackTime > 2.0) {
            musicPlayer.skipToBeginning()
        } else {
            let forcePersist = (indexOfNowPlayingItem - 1) < indexBeforeModification
            if !persistQueueToAudioController(indexOfNowPlayingItem - 1, forcePersist:  forcePersist) {
                musicPlayer.skipToPreviousItem()
            }
        }
    }
    
    func playNow(withTracks tracks:[AudioTrack], startingAtIndex index:Int) {
        KyoozUtils.doInMainQueueAsync() {
            var newContext = NowPlayingQueueContext(originalQueue: tracks)
            newContext.indexOfNowPlayingItem = index >= tracks.count ? 0 : index
            newContext.setShuffleActive(self.shuffleActive)
            
            guard let mediaItems = newContext.currentQueue as? [MPMediaItem] else {
                Logger.error("DRM audio player cannot play tracks that are not MPMediaItem objects")
                return
            }
            
            self.nowPlayingQueueContext = newContext
            self.musicPlayer.setQueueWithItemCollection(MPMediaItemCollection(items: mediaItems))
            self.musicPlayer.nowPlayingItem = mediaItems[newContext.indexOfNowPlayingItem]
            self.musicPlayer.play()
            self.playbackStateManager.correctPlaybackState()
            
            self.queueIsPersisted = true
            self.indexBeforeModification = 0
            self.refreshIndexOfNowPlayingItem()
        }
        
    }
    
    func playItemWithIndexInCurrentQueue(index index:Int) {
        if(index == indexOfNowPlayingItem) { return }
        
        let shouldForcePersist = index < indexBeforeModification
        
        if !persistQueueToAudioController(index, forcePersist: shouldForcePersist) {
            musicPlayer.nowPlayingItem = nowPlayingQueue[index] as? MPMediaItem
            musicPlayer.play()
            playbackStateManager.correctPlaybackState()
        } else if !musicIsPlaying {
            musicPlayer.play()
        }
    }
    
    func enqueue(items itemsToEnqueue:[AudioTrack], atPosition position:EnqueuePosition) {
        nowPlayingQueueContext.enqueue(items: itemsToEnqueue, atPosition: position)
        persistToSystemQueue()
    }
    
    func insertItemsAtIndex(itemsToInsert:[AudioTrack], index:Int) {
        nowPlayingQueueContext.insertItemsAtIndex(itemsToInsert, index: index)
        if(index > indexOfNowPlayingItem || indexOfNowPlayingItem == 0) {
            persistToSystemQueue()
        }
    }
    
    func deleteItemsAtIndices(indiciesToRemove:[Int]) {
        let noOfItemsLeftToPlayBefore = nowPlayingQueueContext.currentQueue.count - nowPlayingQueueContext.indexOfNowPlayingItem
        let nowPlayingItemRemoved = nowPlayingQueueContext.deleteItemsAtIndices(indiciesToRemove)
        if nowPlayingItemRemoved {
            resetQueueStateToBeginning()
            return
        } else {
            let noOfItemsLeftToPlayAfter = nowPlayingQueueContext.currentQueue.count - nowPlayingQueueContext.indexOfNowPlayingItem
            if noOfItemsLeftToPlayBefore != noOfItemsLeftToPlayAfter {
                persistToSystemQueue()
            }
        }
    }
    
    func moveMediaItem(fromIndexPath fromIndexPath:Int, toIndexPath:Int) {
        let index = indexOfNowPlayingItem
        nowPlayingQueueContext.moveMediaItem(fromIndexPath: fromIndexPath, toIndexPath: toIndexPath)
        if index <= fromIndexPath || index < toIndexPath {
            persistToSystemQueue()
        }
    }
    
    func clearItems(towardsDirection direction:ClearDirection, atIndex index:Int) {
        let nowPlayingItemRemoved = nowPlayingQueueContext.clearItems(towardsDirection: direction, atIndex: index)
        if nowPlayingItemRemoved {
            resetQueueStateToBeginning()
        } else {
            persistToSystemQueue()
        }
    }
    
    //MARK: - Class functions
    
    private func persistToSystemQueue() {
        if let queue = nowPlayingQueue as? [MPMediaItem] {

            indexBeforeModification = indexOfNowPlayingItem
            var truncatedQueue = [MPMediaItem]()
            for i in indexOfNowPlayingItem..<queue.count {
                truncatedQueue.append(queue[i])
            }
            
            KyoozUtils.doInMainQueueAsync() {
                self.musicPlayer.setQueueWithItemCollection(MPMediaItemCollection(items: truncatedQueue))
                let item = self.musicPlayer.nowPlayingItem //only doing this because compiler wont allow assigning an object to itself directly
                self.musicPlayer.nowPlayingItem = item //need to invoke the setter so that the queue changes take place
            }
            queueIsPersisted = true
            
        }
    }
    
    private func resetQueueStateToBeginning() {
        if nowPlayingQueue.isEmpty {
            musicPlayer.nowPlayingItem = nil
            musicPlayer.stop()
            return
        }
        
        let musicWasPlaying = musicIsPlaying
        
        nowPlayingQueueContext.indexOfNowPlayingItem = 0
        indexBeforeModification = 0
        musicPlayer.setQueueWithItemCollection(MPMediaItemCollection(items: nowPlayingQueue as! [MPMediaItem]))
        musicPlayer.nowPlayingItem = nowPlayingQueue[indexOfNowPlayingItem] as? MPMediaItem
        if musicWasPlaying  {
            musicPlayer.play()
        }
    }
    
    private func pullSystemQueue() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            if let systemQueue = self.mediaPlayerAPIHelper.getCurrentQueue(self.musicPlayer) {
                KyoozUtils.doInMainQueue() {
                    self.mergeNowPlayingQueue(withQueue: systemQueue)
                }
            }
        }
    }
    
    private func mergeNowPlayingQueue(withQueue systemQueue:[AudioTrack]) {
        if systemQueue.isEmpty {
            resetQueueStateToBeginning()
            return
        }
        
        var mergedQueue = [AudioTrack]()
        mergedQueue.reserveCapacity(indexBeforeModification + systemQueue.count)
        for i in 0..<(indexBeforeModification + systemQueue.count) {
            if i < indexBeforeModification {
                mergedQueue.append(nowPlayingQueue[i])
            } else {
                mergedQueue.append(systemQueue[i - indexBeforeModification])
            }
        }
        if musicPlayer.shuffleMode == .Off && repeatMode != .One && !shuffleActive {
            //if no special playback mode enabled then take the merged queue as the new context
            nowPlayingQueueContext = NowPlayingQueueContext(originalQueue: mergedQueue)
            refreshIndexOfNowPlayingItem()
        } else if musicPlayer.shuffleMode != .Off {
            //if shuffle was enabled in system player then assume the merged queue as the shuffled queue for this app
            //turn off shuffle mode in the system player and persist the shuffled queue
            nowPlayingQueueContext.overrideShuffleQueue(mergedQueue)
            refreshIndexOfNowPlayingItem()
            musicPlayer.shuffleMode = .Off
            persistToSystemQueue()
        } else if shuffleActive {
            //if shuffle was active then override the shuffled queue with the merged queue
            nowPlayingQueueContext.overrideShuffleQueue(mergedQueue)
            refreshIndexOfNowPlayingItem()
        }
        queueIsPersisted = true
        publishNotification(updateType: .PlaybackStateUpdate, sender: self)
    }
    
    private func persistQueueToAudioController(var indexToPlay:Int, forcePersist:Bool = false, completionHandler:()->() = { }) -> Bool {
        if nowPlayingQueue.isEmpty || (queueIsPersisted && !forcePersist ) { return false }
        
        KyoozUtils.doInMainQueueAsync() {
        
            Logger.debug("** PERSISTING NOW PLAYING QUEUE **")
            
            let reachedEndOfQueue = indexToPlay >= self.nowPlayingQueue.count
            if reachedEndOfQueue { indexToPlay = 0 }
            let willPlayNewItem = (indexToPlay != self.indexOfNowPlayingItem) || reachedEndOfQueue
            let playAfterPersisting = self.musicIsPlaying && !reachedEndOfQueue
            
            let currentPlaybackTime:NSTimeInterval? = willPlayNewItem ? nil : self.musicPlayer.currentPlaybackTime
            let trackToPlay:AudioTrack? = willPlayNewItem ? self.nowPlayingQueue[indexToPlay] : self.musicPlayer.nowPlayingItem

            self.musicPlayer.pause()
            self.musicPlayer.setQueueWithItemCollection(MPMediaItemCollection(items: (self.nowPlayingQueue as! [MPMediaItem])))
            self.musicPlayer.nowPlayingItem = trackToPlay as? MPMediaItem

            if let playbackTime = currentPlaybackTime {
                Logger.debug("restoring currentPlaybackTime to \(playbackTime)")
                self.musicPlayer.currentPlaybackTime = playbackTime
                
                dispatch_after(KyoozUtils.getDispatchTimeForSeconds(0.25), dispatch_get_main_queue(), { () -> Void in
                    if(indexToPlay == self.indexOfNowPlayingItem && self.musicPlayer.currentPlaybackTime < 2) {
                        Logger.debug("** CORRECTING PLAYBACK TIME **")
                        self.musicPlayer.currentPlaybackTime = playbackTime
                    }
                    completionHandler()
                })
            }
            
            Logger.debug("playAfterPersisting=\(playAfterPersisting)")
            if playAfterPersisting ||
                (self.playbackStateManager.musicPlaybackState == MPMusicPlaybackState.Stopped && !reachedEndOfQueue) {
                self.musicPlayer.play()
            }
            
            self.playbackStateManager.correctPlaybackState()
            
            self.queueIsPersisted = true
            self.indexBeforeModification = 0
        }
        return true
    }
    
    private func refreshIndexOfNowPlayingItem() {
        let i = musicPlayer.indexOfNowPlayingItem
        let currentIndex = i < nowPlayingQueue.count ? i : 0
        indexOfNowPlayingItem = currentIndex + indexBeforeModification
    }
    
    
    //MARK: - Notification handling functions
    
    func handleNowPlayingItemChanged(notification:NSNotification) {
        persistQueueToAudioController(indexOfNowPlayingItem + 1)
        
        refreshIndexOfNowPlayingItem()
        
        publishNotification(updateType: .NowPlayingItemChanged, sender: self)
    }
    
    func handlePlaybackStateChanged(notification:NSNotification) {
        publishNotification(updateType: .PlaybackStateUpdate, sender: self)
    }
    
    func handleApplicationDidResignActive(notification:NSNotification) {
        if(!isMultiTaskingSupported() || (!musicIsPlaying && !playbackStateManager.otherMusicIsPlaying())) {
            persistQueueWithCurrentItem()
            return
        }

        if(queueIsPersisted || playbackStateManager.otherMusicIsPlaying()) { return }
        
        if(backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            endBackgroundTask()
        }

        timer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "resignActiveIfQueueIsPersisted:",
            userInfo: nil, repeats: true)
        let taskName = "waitForQueuePersistenceTask"

        Logger.debug("Starting background task: \(taskName), backgroundTimeRemaining:\(UIApplication.sharedApplication().backgroundTimeRemaining)")
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithName(taskName,
            expirationHandler: { [weak self]() in
                if !self!.persistQueueToAudioController(self!.indexOfNowPlayingItem, completionHandler: self!.endBackgroundTask) {
                    self!.endBackgroundTask()
                }
        })
        
    }
    
    func handleApplicationDidBecomeActive(notification:NSNotification) {
        if(backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            endBackgroundTask()
        }
        playbackStateManager.correctPlaybackState()
        
        pullSystemQueue()
    }
    
    func handleApplicationWillTerminate(notification:NSNotification) {
        if !persistQueueToAudioController(indexOfNowPlayingItem, completionHandler: endBackgroundTask) {
            endBackgroundTask()
        }
    }
    
    func persistQueueWithCurrentItem() {
        persistQueueToAudioController(indexOfNowPlayingItem)
    }
    
    private func registerForMediaPlayerNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "handleNowPlayingItemChanged:",
            name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification,
            object: musicPlayer)
        notificationCenter.addObserver(self, selector: "handlePlaybackStateChanged:",
            name:MPMusicPlayerControllerPlaybackStateDidChangeNotification,
            object: musicPlayer)
        notificationCenter.addObserver(self, selector: "handlePlaybackStateChanged:",
            name:PlaybackStateManager.PlaybackStateCorrectedNotification,
            object: playbackStateManager)
        
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        let application = UIApplication.sharedApplication()
        notificationCenter.addObserver(self, selector: "handleApplicationDidResignActive:",
            name: UIApplicationWillResignActiveNotification, object: application)
        notificationCenter.addObserver(self, selector: "handleApplicationDidBecomeActive:",
            name: UIApplicationDidBecomeActiveNotification, object: application)
        notificationCenter.addObserver(self, selector: "handleApplicationWillTerminate:",
            name: UIApplicationWillTerminateNotification, object: application)
        
    }
    
    private func unregisterForMediaPlayerNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self)
    }
    
    
    //MARK: - Background Handling Functions
    

    func endBackgroundTask() {
        KyoozUtils.doInMainQueueAsync() {
            if let uwTimer = self.timer {
                Logger.debug("Ending background task: " + self.backgroundTaskIdentifier.description)
                uwTimer.invalidate()
                self.timer = nil
                UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier)
                self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
            }
        }
    }

    func resignActiveIfQueueIsPersisted(sender: NSTimer) {
        if(queueIsPersisted || playbackStateManager.otherMusicIsPlaying()) {
            endBackgroundTask()
        } else {
            Logger.debug("queue is not yet persisted.  background time remaining:\(UIApplication.sharedApplication().backgroundTimeRemaining)")
        }
    }

    func isMultiTaskingSupported() -> Bool {
        return UIDevice.currentDevice().multitaskingSupported
    }
    
}