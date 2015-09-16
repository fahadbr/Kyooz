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
    
    private var queueIsPersisted:Bool = false
    
    override init() {
        super.init()
        
        registerForMediaPlayerNotifications()
        if let queueFromTempStorage = TempDataDAO.instance.getNowPlayingQueueFromTempStorage(){
            if let nowPlayingItem = musicPlayer.nowPlayingItem {
                let index = musicPlayer.indexOfNowPlayingItem
                //check if the queue from temp storage matches with the queue in the current music player
                if(index < queueFromTempStorage.count && queueFromTempStorage[index].id == nowPlayingItem.id) {
                    Logger.debug("restoring now playing queue from temp storage")
                    self.nowPlayingQueue = queueFromTempStorage
                    queueIsPersisted = true
                    return
                }
            }
        }
        if let nowPlayingItem = musicPlayer.nowPlayingItem {
            var query = MPMediaQuery()
            query.addFilterPredicate(MPMediaPropertyPredicate(value: NSNumber(unsignedLongLong: nowPlayingItem.albumPersistentID),
                forProperty: MPMediaItemPropertyAlbumPersistentID,
                comparisonType: MPMediaPredicateComparison.EqualTo))
            Logger.debug("assuming now playing queue to be album")
            self.nowPlayingQueue = query.items as! [AudioTrack]
            
        }
    }
    
    deinit {
        unregisterForMediaPlayerNotifications()
    }

    
    //MARK: AudioQueuePlayer - Properties
    var nowPlayingQueue:[AudioTrack] = [AudioTrack]() {
        didSet {
            AudioQueuePlayerNotificationPublisher.publishNotification(updateType: .QueueUpdate, sender: self)
            queueIsPersisted = false
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), { () -> Void in
            self.persistQueueToAudioController(indexOfNowPlayingItem)
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
            if !persistQueueToAudioController(indexOfNowPlayingItem - 1) {
                musicPlayer.skipToPreviousItem()
            }
        }
    }
    
    func playNowWithCollection(#mediaCollection:MPMediaItemCollection, itemToPlay:AudioTrack) {
        if let mediaItems = mediaCollection.items as? [AudioTrack] {
            nowPlayingQueue = mediaItems
            musicPlayer.setQueueWithItemCollection(mediaCollection)
            musicPlayer.nowPlayingItem = itemToPlay as! MPMediaItem
            musicPlayer.play()
            playbackStateManager.correctPlaybackState()
            
            queueIsPersisted = true
            indexOfNowPlayingItem = 0
        }
    }
    
    func playItemWithIndexInCurrentQueue(#index:Int) {
        if(index == indexOfNowPlayingItem) { return }
        
        if !persistQueueToAudioController(index) {
            musicPlayer.nowPlayingItem = nowPlayingQueue[index] as! MPMediaItem
            musicPlayer.play()
            playbackStateManager.correctPlaybackState()
        } else if !musicIsPlaying {
            musicPlayer.play()
        }
    }
    
    func enqueue(itemsToEnqueue:[AudioTrack]) {
        nowPlayingQueue.extend(itemsToEnqueue)
    }
    
    func insertItemsAtIndex(itemsToInsert:[AudioTrack], index:Int) {
        nowPlayingQueue.insertAtIndex(itemsToInsert, index: index, placeHolderItem: MPMediaItem())
        if(index <= indexOfNowPlayingItem) {
            indexOfNowPlayingItem += itemsToInsert.count
        }
    }
    
    func deleteItemsAtIndices(indiciesToRemove:[Int]) {
        queueIsPersisted = false
        var indicies = indiciesToRemove
        if(indicies.count > 1) {
            //if removing more than 1 element, sort the array otherwise we will run into index out of bounds issues
            indicies.sort { $0 > $1 }
        }
        var nowPlayingItemRemoved = false
        for index in indicies {
            nowPlayingQueue.removeAtIndex(index)
            if(index < indexOfNowPlayingItem) {
                indexOfNowPlayingItem--
            } else if (index == indexOfNowPlayingItem) {
                nowPlayingItemRemoved = true
            }
        }
        
        if(nowPlayingItemRemoved) {
            resetQueueStateToBeginning()
        }
    }
    
    func moveMediaItem(#fromIndexPath:Int, toIndexPath:Int) {
        let tempMediaItem = nowPlayingQueue[fromIndexPath]
        nowPlayingQueue.removeAtIndex(fromIndexPath)
        nowPlayingQueue.insert(tempMediaItem, atIndex: toIndexPath)
        
        if(fromIndexPath == indexOfNowPlayingItem) {
            indexOfNowPlayingItem = toIndexPath
        } else if(fromIndexPath < indexOfNowPlayingItem && indexOfNowPlayingItem <= toIndexPath) {
            indexOfNowPlayingItem--
        } else if(toIndexPath <= indexOfNowPlayingItem && indexOfNowPlayingItem < fromIndexPath) {
            indexOfNowPlayingItem++
        }
    }
    
    func clearUpcomingItems(#fromIndex:Int) {
        nowPlayingQueue.removeRange((fromIndex + 1)..<nowPlayingQueue.count)
        if(fromIndex < indexOfNowPlayingItem) {
            resetQueueStateToBeginning()
        }
    }
    
    //MARK: - Class functions
    
    private func resetQueueStateToBeginning() {
        let musicWasPlaying = musicIsPlaying
        
        indexOfNowPlayingItem = 0
        musicPlayer.nowPlayingItem = nowPlayingQueue[indexOfNowPlayingItem] as! MPMediaItem
        if musicWasPlaying  {
            musicPlayer.play()
        }
    }
    
    
    private func persistQueueToAudioController(var indexToPlay:Int, completionHandler:()->() = { }) -> Bool {
        if(queueIsPersisted || nowPlayingQueue.isEmpty) { return false }
        
        Logger.debug("** PERSISTING NOW PLAYING QUEUE **")
        
        let reachedEndOfQueue = indexToPlay >= nowPlayingQueue.count
        if reachedEndOfQueue { indexToPlay = 0 }
        let willPlayNewItem = (indexToPlay != indexOfNowPlayingItem) || reachedEndOfQueue
        let playAfterPersisting = musicIsPlaying && !reachedEndOfQueue
        
        let currentPlaybackTime:NSTimeInterval? = willPlayNewItem ? nil : musicPlayer.currentPlaybackTime
        let trackToPlay = willPlayNewItem ? nowPlayingQueue[indexToPlay] : musicPlayer.nowPlayingItem

        musicPlayer.pause()
        musicPlayer.setQueueWithItemCollection(MPMediaItemCollection(items: nowPlayingQueue))
        musicPlayer.nowPlayingItem = trackToPlay as! MPMediaItem

        if let playbackTime = currentPlaybackTime {
            Logger.debug("restoring currentPlaybackTime to \(playbackTime)")
            musicPlayer.currentPlaybackTime = playbackTime
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), { () -> Void in
                if(indexToPlay == self.indexOfNowPlayingItem && self.musicPlayer.currentPlaybackTime < 2) {
                    Logger.debug("** CORRECTING PLAYBACK TIME **")
                    self.musicPlayer.currentPlaybackTime = playbackTime
                }
                completionHandler()
            })
        }
        
        if playAfterPersisting {
            musicPlayer.play()
        }
        
        playbackStateManager.correctPlaybackState()
        
        queueIsPersisted = true
        return true
    }
    
    
    //MARK: - Notification handling functions
    
    func handleNowPlayingItemChanged(notification:NSNotification) {
        persistQueueToAudioController(indexOfNowPlayingItem + 1)
        
        indexOfNowPlayingItem = musicPlayer.indexOfNowPlayingItem < nowPlayingQueue.count ? musicPlayer.indexOfNowPlayingItem : 0
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
    }
    
    func handleApplicationWillTerminate(notification:NSNotification) {
        if !persistQueueToAudioController(indexOfNowPlayingItem, completionHandler: endBackgroundTask) {
            endBackgroundTask()
        }
    }
    
    func persistQueueWithCurrentItem() {
        persistQueueToAudioController(indexOfNowPlayingItem)
    }
    
    var obsContext:UInt8 = 0
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
        
        musicPlayer.addObserver(self, forKeyPath: "nowPlayingItem", options: NSKeyValueObservingOptions.New, context: &obsContext)
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
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        Logger.debug("keyPath changed: \(keyPath)")
    }
    
    //MARK: - Background Handling Functions
    

    func endBackgroundTask() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let uwTimer = self.timer {
                Logger.debug("Ending background task: " + self.backgroundTaskIdentifier.description)
                uwTimer.invalidate()
                self.timer = nil
                UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier)
                self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
            }
        })
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