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

class DRMAudioQueuePlayer: NSObject, AudioQueuePlayer {
    static let instance = DRMAudioQueuePlayer()
    
    private let musicPlayer = ApplicationDefaults.defaultMusicPlayerController
    private let playbackStateManager = PlaybackStateManager.instance
    
    private var timer: NSTimer?
    private var backgroundTaskIdentifier:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    private var queueIsPersisted:Bool = true
    private let indexBeforeModificationKey = "indexBeforeModification"
    private let mediaPlayerAPIHelper = MediaPlayerAPIHelper()
    
    private var indexBeforeModification:Int = 0 {
        didSet {
            TempDataDAO.instance.addPersistentValue(key: indexBeforeModificationKey, value: NSNumber(integer: indexBeforeModification))
        }
    }
    
    override init() {
        super.init()
        registerForMediaPlayerNotifications()
        
        if let queueFromTempStorage = TempDataDAO.instance.getNowPlayingQueueFromTempStorage(){
            Logger.debug("restoring now playing queue from temp storage")
            nowPlayingQueue = queueFromTempStorage
        }
        
        if let indexBeforeMod = TempDataDAO.instance.getPersistentValue(key: indexBeforeModificationKey) as? NSNumber {
            indexBeforeModification = indexBeforeMod.longValue
        }
        
        if pullCurrentQueueInSystemPlayer() {
            return
        }
    }
    
    deinit {
        unregisterForMediaPlayerNotifications()
    }

    
    //MARK: AudioQueuePlayer - Properties
    var nowPlayingQueue:[AudioTrack] = [AudioTrack]() {
        didSet {
            AudioQueuePlayerNotificationPublisher.publishNotification(updateType: AudioQueuePlayerUpdate.QueueUpdate, sender: self)
        }
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
                AudioQueuePlayerNotificationPublisher.publishNotification(updateType: .PlaybackStateUpdate, sender: self)
            }
        }
    }
    
    var indexOfNowPlayingItem:Int = 0
    
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
    
    func playNowWithCollection(mediaCollection mediaCollection:MPMediaItemCollection, itemToPlay:AudioTrack) {
        let mediaItems = mediaCollection.items
        KyoozUtils.doInMainQueueAsync() {
            self.nowPlayingQueue = mediaItems
            self.musicPlayer.setQueueWithItemCollection(mediaCollection)
            self.musicPlayer.nowPlayingItem = itemToPlay as? MPMediaItem
            self.musicPlayer.play()
            self.playbackStateManager.correctPlaybackState()
            
            self.queueIsPersisted = true
            self.indexOfNowPlayingItem = self.musicPlayer.indexOfNowPlayingItem
            self.indexBeforeModification = 0
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
    
    func enqueue(itemsToEnqueue:[AudioTrack]) {
        nowPlayingQueue.appendContentsOf(itemsToEnqueue)
        persistToSystemQueue()
    }
    
    func insertItemsAtIndex(itemsToInsert:[AudioTrack], index:Int) {
        nowPlayingQueue.insertAtIndex(itemsToInsert, index: index, placeHolderItem: MPMediaItem())
        if(index <= indexOfNowPlayingItem) {
            indexOfNowPlayingItem += itemsToInsert.count
        } else {
            persistToSystemQueue()
        }
    }
    
    func deleteItemsAtIndices(indiciesToRemove:[Int]) {
        var shouldPersist = false
        var indicies = indiciesToRemove
        if(indicies.count > 1) {
            //if removing more than 1 element, sort the array otherwise we will run into index out of bounds issues
            indicies.sortInPlace { $0 > $1 }
        }
        var nowPlayingItemRemoved = false
        for index in indicies {
            nowPlayingQueue.removeAtIndex(index)
            if(index < indexOfNowPlayingItem) {
                indexOfNowPlayingItem--
                if index < indexBeforeModification {
                    indexBeforeModification--
                }
            } else if (index == indexOfNowPlayingItem) {
                nowPlayingItemRemoved = true
                shouldPersist = true
            } else {
                shouldPersist = true
            }
        }
        
        if nowPlayingItemRemoved {
            resetQueueStateToBeginning()
        }
        if shouldPersist {
            persistToSystemQueue()
        }
    }
    
    func moveMediaItem(fromIndexPath fromIndexPath:Int, toIndexPath:Int) {
        let tempMediaItem = nowPlayingQueue[fromIndexPath]
        nowPlayingQueue.removeAtIndex(fromIndexPath)
        nowPlayingQueue.insert(tempMediaItem, atIndex: toIndexPath)
        var shouldPersist = true
        
        if fromIndexPath == indexOfNowPlayingItem {
            indexOfNowPlayingItem = toIndexPath
        } else if fromIndexPath < indexOfNowPlayingItem && indexOfNowPlayingItem <= toIndexPath {
            indexOfNowPlayingItem--
        } else if toIndexPath <= indexOfNowPlayingItem && indexOfNowPlayingItem < fromIndexPath {
            indexOfNowPlayingItem++
        } else if fromIndexPath < indexOfNowPlayingItem && toIndexPath < indexOfNowPlayingItem {
            shouldPersist = false
        }
        
        if shouldPersist {
            persistToSystemQueue()
        }
    }
    
    func clearUpcomingItems(fromIndex fromIndex:Int) {
        nowPlayingQueue.removeRange((fromIndex + 1)..<nowPlayingQueue.count)
        if(fromIndex < indexOfNowPlayingItem) {
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
            
            musicPlayer.setQueueWithItemCollection(MPMediaItemCollection(items: truncatedQueue))
            let item = musicPlayer.nowPlayingItem //only doing this because compiler wont allow assigning an object to itself directly
            musicPlayer.nowPlayingItem = item //need to invoke the setter so that the queue changes take place
            
            queueIsPersisted = true
        }
    }
    
    private func resetQueueStateToBeginning() {
        if nowPlayingQueue.isEmpty { return }
        
        let musicWasPlaying = musicIsPlaying
        
        indexOfNowPlayingItem = 0
        indexBeforeModification = 0
        musicPlayer.setQueueWithItemCollection(MPMediaItemCollection(items: nowPlayingQueue as! [MPMediaItem]))
        musicPlayer.nowPlayingItem = nowPlayingQueue[indexOfNowPlayingItem] as? MPMediaItem
        if musicWasPlaying  {
            musicPlayer.play()
        }
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
        let currentIndex = musicPlayer.indexOfNowPlayingItem < nowPlayingQueue.count ? musicPlayer.indexOfNowPlayingItem : 0
        indexOfNowPlayingItem = currentIndex + indexBeforeModification
    }
    
    
    //MARK: - Notification handling functions
    
    func handleNowPlayingItemChanged(notification:NSNotification) {
        persistQueueToAudioController(indexOfNowPlayingItem + 1)
        
        refreshIndexOfNowPlayingItem()
        
        AudioQueuePlayerNotificationPublisher.publishNotification(updateType: .NowPlayingItemChanged, sender: self)
    }
    
    func handlePlaybackStateChanged(notification:NSNotification) {
        AudioQueuePlayerNotificationPublisher.publishNotification(updateType: .PlaybackStateUpdate, sender: self)
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
        
        KyoozUtils.doInMainQueue() {
            self.pullCurrentQueueInSystemPlayer()
        }
    }
    
    private func pullCurrentQueueInSystemPlayer() -> Bool {
        if let currentQueue = mediaPlayerAPIHelper.getCurrentQueue(self.musicPlayer) {
            if currentQueue.isEmpty {
                resetQueueStateToBeginning()
                return true
            }
            
            var mergedQueue = [AudioTrack]()
            for i in 0..<(indexBeforeModification + currentQueue.count) {
                if i < indexBeforeModification {
                    mergedQueue.append(nowPlayingQueue[i])
                } else {
                    mergedQueue.append(currentQueue[i - indexBeforeModification])
                }
            }
            nowPlayingQueue = mergedQueue
            queueIsPersisted = true
            refreshIndexOfNowPlayingItem()
            return true
        }
        return false
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