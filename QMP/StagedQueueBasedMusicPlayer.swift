//
//  NowPlayingQueueManager.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer
import AVFoundation

class StagedQueueBasedMusicPlayer : NSObject{
    
    class var instance : StagedQueueBasedMusicPlayer {
        struct Static {
            static let instance:StagedQueueBasedMusicPlayer = StagedQueueBasedMusicPlayer()
        }
        return Static.instance
    }
    
    //MARK: PROPERTIES
    private let musicPlayer = MusicPlayerContainer.defaultMusicPlayerController
    private let playbackStateManager = PlaybackStateManager.instance
    private let timeDelayInNanoSeconds = Int64(1.0 * Double(NSEC_PER_SEC))
    
    private var nowPlayingQueue:[MPMediaItem]? = [MPMediaItem]() {
        didSet {
            if(nowPlayingQueue!.count > oldValue!.count) {
                Logger.debug("publishing notification for queue change")
//                QueueBasedMusicPlayerNotificationPublisher.publishNotification(updateType: .QueueUpdate, sender:self)
            }
        }
    }
    private var stagedQueue:[MPMediaItem]? = [MPMediaItem]() {
        didSet {
            if(stagedQueue!.count > oldValue!.count) {
                Logger.debug("publishing notification for queue change")
//                QueueBasedMusicPlayerNotificationPublisher.publishNotification(updateType: .QueueUpdate, sender:self)
            }
        }
    }
    
    private var nextStagedMediaItem:MPMediaItem?
    private var indexOfNextStagedItemExceedsNowPlayingQueueLength:Bool = false
    

    //MARK: COMPUTED PROPERTIES
    var nowPlayingItem:MPMediaItem? {
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
            }
        }
    }
    
    var indexOfNowPlayingItem:Int {
        var indexToReturn = 0
        
        if(stagedQueueIsEmpty()) {
            indexToReturn = musicPlayer.indexOfNowPlayingItem
        } else {
            var i = 0
            for mediaItem in getNowPlayingQueue()! {
                if((self.nowPlayingItem?.persistentID ?? 0) == mediaItem.persistentID) {
                    indexToReturn = i
                    break
                }
                i++
            }
        }
        return indexToReturn
    }
    
    //MARK: INIT/DE-INITS
    
    override init() {
        super.init()
        registerForMediaPlayerNotifications()
        
        if let queueFromTempStorage = TempDataDAO.instance.getNowPlayingQueueFromTempStorage(){
            if let nowPlayingItem = musicPlayer.nowPlayingItem {
                let index = musicPlayer.indexOfNowPlayingItem
                //check if the queue from temp storage matches with the queue in the current music player
                if(index < queueFromTempStorage.count && queueFromTempStorage[index].persistentID == nowPlayingItem.persistentID) {
                    Logger.debug("restoring now playing queue from temp storage")
                    self.nowPlayingQueue = queueFromTempStorage
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
            self.nowPlayingQueue = query.items as? [MPMediaItem]
        }
    }
    
    deinit {
        TempDataDAO.instance.persistNowPlayingQueueToTempStorage(getNowPlayingQueue())
        unregisterForMediaPlayerNotifications()
    }
    
    //MARK:QueueBasedMusicPlayer Functions
    func play() {
        promoteStagedQueueWithCurrentNowPlayingItem()
        musicPlayer.play()
    }
    
    func pause() {
        promoteStagedQueueWithCurrentNowPlayingItem()
        musicPlayer.pause()
    }
    
    func skipForwards() {
        musicPlayer.skipToNextItem()
    }
    
    func skipBackwards() {
        if(currentPlaybackTime < 2.0) {
            musicPlayer.skipToPreviousItem()
        } else {
            musicPlayer.skipToBeginning()
        }
    }
    
    func getNowPlayingQueue() -> [MPMediaItem]? {
        if(stagedQueueIsEmpty()) {
            return nowPlayingQueue
        } else {
            return stagedQueue
        }
        
    }
    
    func moreBackgroundTimeIsNeeded() -> Bool {
        return !stagedQueueIsEmpty()
    }
    
    func executePreBackgroundTasks() {
        promoteStagedQueueWithCurrentNowPlayingItem()
    }
    
    func enqueue(itemsToEnqueue:[MPMediaItem]) {

        var queue = getNowPlayingQueue()
        
        if(queue != nil) {
            queue?.extend(itemsToEnqueue)
        } else {
            queue = itemsToEnqueue
        }
        let playbackState = getPlaybackState()
        setQueueInternal(queue!, itemToPlay:playbackState.nowPlayingItem)
        restorePlaybackState(playbackState, override: false, restoreFullState:true)
        evaluateNextStagedMediaItem(playbackState)
        
    }
    
    func playNowWithCollection(#mediaCollection:MPMediaItemCollection, itemToPlay:MPMediaItem) {
        resetAllStagedObjects()
        setNowPlayingQueue(mediaCollection, itemToPlay: itemToPlay)
        musicPlayer.play()
        playbackStateManager.correctPlaybackState()
    }
    
    func playItemWithIndexInCurrentQueue(#index:Int) {
        let queue = getNowPlayingQueue()
        let itemToPlay = queue?[index]
                
        promoteStagedQueueToNowPlaying(itemToPlay, restoreFullState: false)
        musicPlayer.nowPlayingItem = itemToPlay
        musicPlayer.play()
        playbackStateManager.correctPlaybackState()
    }
    
    func clearUpcomingItems(#fromIndex:Int) {
        var queue = self.getNowPlayingQueue()!
        
        
        Logger.debug("clearing now playing queue from index \(fromIndex)")
        queue.removeRange(Range<Int>(start: fromIndex + 1, end: queue.count))
        
        let playbackState = getPlaybackState()
        let mediaItemToPlay = queue[fromIndex]
        setQueueInternal(queue, itemToPlay: mediaItemToPlay)
        if(mediaItemToPlay.persistentID == playbackState.nowPlayingItem!.persistentID) {
            restorePlaybackState(playbackState, override: false, restoreFullState: true)
        }
    }
    
    func deleteItemsAtIndices(index:[Int]) {
//        var queue = getNowPlayingQueue()
//
//
//        if(queue == nil || index > (queue!.count - 1)) {
//            return
//        }
//        
//        let playbackState = getPlaybackState()
//        queue!.removeAtIndex(index)
//        setQueueInternal(queue!, itemToPlay: playbackState.nowPlayingItem)
//        restorePlaybackState(playbackState, override: false, restoreFullState: true)
//        evaluateNextStagedMediaItem(playbackState)
        
    }
    
    func moveMediaItem(#fromIndexPath:Int, toIndexPath:Int) {
        var queue = getNowPlayingQueue()
        
        if(queue == nil || fromIndexPath > (queue!.count - 1) || toIndexPath > (queue!.count - 1)) {
            return
        }
        
        let playbackState = getPlaybackState()
        let mediaItem = queue![fromIndexPath]
        queue!.removeAtIndex(fromIndexPath)
        queue!.insert(mediaItem, atIndex: toIndexPath)
        setQueueInternal(queue!, itemToPlay: playbackState.nowPlayingItem)
        restorePlaybackState(playbackState, override: false, restoreFullState: true)
        evaluateNextStagedMediaItem(playbackState)
    }
   
    //MARK:Class Functions
    func handleNowPlayingItemChanged(notification:NSNotification) {
        var message = "NowPlayingItemChanged notification received: "
        if(notification.userInfo != nil) {
            let persistentIDObj: AnyObject? = notification.userInfo!["MPMusicPlayerControllerNowPlayingItemPersistentIDKey"]
            var query = MPMediaQuery.songsQuery()
            query.addFilterPredicate(MPMediaPropertyPredicate(value: persistentIDObj, forProperty: MPMediaItemPropertyPersistentID))
            let items = query.items;
            if(items != nil && !items.isEmpty) {
                let song = (query.items as! [MPMediaItem])[0]
                message += song.title + ", Artist: " + song.albumArtist
            }
        }
        Logger.debug(message)
        promoteStagedQueueToNowPlaying(nextStagedMediaItem, restoreFullState: false)
//        QueueBasedMusicPlayerNotificationPublisher.publishNotification(updateType: .NowPlayingItemChanged, sender:self)
    }
    
    func handlePlaybackStateChanged(notification:NSNotification) {
        if(notification.userInfo != nil) {
            var object: AnyObject? = notification.userInfo!["MPMusicPlayerControllerPlaybackStateKey"]
            if(object != nil) {
                var stateRawValue = object! as! Int
                var stateToSet = MPMusicPlaybackState(rawValue: stateRawValue)
                if(stateToSet != nil && MPMusicPlaybackState.Paused == stateToSet!) {
                    let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, timeDelayInNanoSeconds)
                    let queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
                    dispatch_after(dispatchTime, queue, { [weak self] ()  in
                        if(!self!.playbackStateManager.musicIsPlaying()) {
                            self!.promoteStagedQueueWithCurrentNowPlayingItem()
                        }
                    })
                }
            }
        }
//        QueueBasedMusicPlayerNotificationPublisher.publishNotification(updateType: .PlaybackStateUpdate, sender:self)
    }
    
    
    private func stagedQueueIsEmpty() -> Bool {
        return (stagedQueue == nil || stagedQueue!.isEmpty)
    }
    
    private func promoteStagedQueueWithCurrentNowPlayingItem() {
        self.promoteStagedQueueToNowPlaying(musicPlayer.nowPlayingItem, restoreFullState: true)
    }
    
    private func setQueueInternal(mediaItems:[MPMediaItem], itemToPlay:MPMediaItem?) {
        if(playbackStateManager.musicIsPlaying() || playbackStateManager.otherMusicIsPlaying()) {
            Logger.debug("Setting staged queue")
            stagedQueue = mediaItems
        } else {
            setNowPlayingQueue(MPMediaItemCollection(items: mediaItems), itemToPlay: itemToPlay)
        }
    }
    
    private func setNowPlayingQueue(mediaCollection:MPMediaItemCollection, itemToPlay:MPMediaItem?) {
        if(mediaCollection.items != nil) {
            Logger.debug("Setting now playing queue")
            
            nowPlayingQueue = mediaCollection.items as? [MPMediaItem]
            musicPlayer.setQueueWithItemCollection(mediaCollection)
            if(itemToPlay != nil) {
                musicPlayer.nowPlayingItem = itemToPlay!
            }
        }
    }
    
    private func resetAllStagedObjects() {
        stagedQueue?.removeAll(keepCapacity: false)
        nextStagedMediaItem = nil
        indexOfNextStagedItemExceedsNowPlayingQueueLength = false
    }
    
    private func evaluateNextStagedMediaItem(playbackState: PlaybackStateDTO) {
        if(playbackState.nowPlayingItem == nil || stagedQueueIsEmpty()) {
            return
        }
        
        let unwrappedMediaItem = playbackState.nowPlayingItem!
        let unwrappedQueue = getNowPlayingQueue()!
        for var i=0 ; i<unwrappedQueue.count ; i++ {
            if(unwrappedMediaItem.persistentID == unwrappedQueue[i].persistentID) {
                if(i >= (nowPlayingQueue!.count - 1) && i >= playbackState.nowPlayingIndex!) {
                    indexOfNextStagedItemExceedsNowPlayingQueueLength = true
                }
                let nextIndex = i+1
                if(nextIndex < unwrappedQueue.count) {
                    nextStagedMediaItem = unwrappedQueue[nextIndex]
                }
                break
            }
        }
    }
    
    private func promoteStagedQueueToNowPlaying(itemToPlay:MPMediaItem?, restoreFullState:Bool) {
        if(stagedQueueIsEmpty()) {
            return
        }
        Logger.debug("PROMOTING STAGED QUEUE")
        let playbackState = getPlaybackState()
        setNowPlayingQueue(MPMediaItemCollection(items: stagedQueue), itemToPlay: itemToPlay)
        
        restorePlaybackState(playbackState, override: true, restoreFullState:restoreFullState)
        resetAllStagedObjects()
        playbackStateManager.correctPlaybackState()
    }
    
    private func getPlaybackState() -> PlaybackStateDTO {
        let playbackState =  PlaybackStateDTO(musicIsPlaying: playbackStateManager.musicIsPlaying(),
            nowPlayingItem: musicPlayer.nowPlayingItem,
            nowPlayingIndex: musicPlayer.indexOfNowPlayingItem,
            currentPlaybackTime: musicPlayer.currentPlaybackTime)
        Logger.debug(playbackState.description)
        return playbackState
    }
    
    private func restorePlaybackState(originalPlaybackState:PlaybackStateDTO, override:Bool, restoreFullState:Bool) {
        if(!override) {
            if(playbackStateManager.musicIsPlaying() || playbackStateManager.otherMusicIsPlaying()) {
                //assume that the staged queue was set and the playback state does not need to be restored
                Logger.debug("Skipping restoring of playback state")
                return
            }
        }
        
        Logger.debug("Restoring playback state: " + originalPlaybackState.description)
        if(restoreFullState) {
            musicPlayer.nowPlayingItem = originalPlaybackState.nowPlayingItem
            musicPlayer.currentPlaybackTime = originalPlaybackState.currentPlaybackTime!
        }
        
        if(originalPlaybackState.musicIsPlaying || indexOfNextStagedItemExceedsNowPlayingQueueLength) {
            musicPlayer.play()
        }
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
            object: PlaybackStateManager.instance)
        musicPlayer.beginGeneratingPlaybackNotifications()
    }
    
    private func unregisterForMediaPlayerNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification, object: musicPlayer)
        notificationCenter.removeObserver(self, name: MPMusicPlayerControllerPlaybackStateDidChangeNotification, object: musicPlayer)
        musicPlayer.endGeneratingPlaybackNotifications()
    }
    
    
}