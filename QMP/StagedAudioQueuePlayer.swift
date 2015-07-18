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

class StagedAudioQueuePlayer : NSObject, AudioQueuePlayer{
    
    class var instance : StagedAudioQueuePlayer {
        struct Static {
            static let instance:StagedAudioQueuePlayer = StagedAudioQueuePlayer()
        }
        return Static.instance
    }
    
    //MARK: PROPERTIES
    private let musicPlayer = ApplicationDefaults.defaultMusicPlayerController
    private let playbackStateManager = PlaybackStateManager.instance
    private let timeDelayInNanoSeconds = Int64(1.0 * Double(NSEC_PER_SEC))
    
    private var persistedQueue:[AudioTrack] = [AudioTrack]() {
        didSet {
            if(persistedQueue.count > oldValue.count) {
                Logger.debug("publishing notification for queue change")
//                AudioQueuePlayerNotificationPublisher.publishNotification(updateType: .QueueUpdate, sender:self)
            }
        }
    }
    private var stagedQueue:[AudioTrack] = [AudioTrack]() {
        didSet {
            if(stagedQueue.count > oldValue.count) {
                Logger.debug("publishing notification for queue change")
//                AudioQueuePlayerNotificationPublisher.publishNotification(updateType: .QueueUpdate, sender:self)
            }
        }
    }
    
    private var nextStagedMediaItem:AudioTrack?
    private var indexOfNextStagedItemExceedsNowPlayingQueueLength:Bool = false
    

    //MARK: COMPUTED PROPERTIES
    var nowPlayingItem:AudioTrack? {
        return musicPlayer.nowPlayingItem
    }
    
    var musicIsPlaying:Bool {
        return playbackStateManager.musicIsPlaying()
    }
    
    var nowPlayingQueue:[AudioTrack] {
        if(stagedQueueIsEmpty()) {
            return persistedQueue
        } else {
            return stagedQueue
        }
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
            for mediaItem in nowPlayingQueue {
                if((self.nowPlayingItem?.id ?? 0) == mediaItem.id) {
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
//        registerForRemoteCommands()
        if let queueFromTempStorage = TempDataDAO.instance.getNowPlayingQueueFromTempStorage(){
            if let nowPlayingItem = musicPlayer.nowPlayingItem {
                let index = musicPlayer.indexOfNowPlayingItem
                //check if the queue from temp storage matches with the queue in the current music player
                if(index < queueFromTempStorage.count && queueFromTempStorage[index].id == nowPlayingItem.id) {
                    Logger.debug("restoring now playing queue from temp storage")
                    self.persistedQueue = queueFromTempStorage
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
            self.persistedQueue = query.items as! [AudioTrack]
        }
    }
    
    deinit {
        unregisterForMediaPlayerNotifications()
//        unregisterForRemoteCommands()
    }
    
    //MARK:AudioQueuePlayer Functions
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
    
    func moreBackgroundTimeIsNeeded() -> Bool {
        return false
    }
    
    func executePreBackgroundTasks() {
        promoteStagedQueueWithCurrentNowPlayingItem()
    }
    
    func enqueue(itemsToEnqueue:[AudioTrack]) {

        var queue = nowPlayingQueue
        

        queue.extend(itemsToEnqueue)
        
        let playbackState = getPlaybackState()
        setQueueInternal(queue, itemToPlay:playbackState.nowPlayingItem)
        restorePlaybackState(playbackState, override: false, restoreFullState:true)
        evaluateNextStagedMediaItem(playbackState)
        
    }
    
    func playNowWithCollection(#mediaCollection:MPMediaItemCollection, itemToPlay:AudioTrack) {
        resetAllStagedObjects()
        setNowPlayingQueue(mediaCollection, itemToPlay: itemToPlay)
        musicPlayer.play()
        playbackStateManager.correctPlaybackState()
    }
    
    func playItemWithIndexInCurrentQueue(#index:Int) {
        let queue = nowPlayingQueue
        let itemToPlay = queue[index]
                
        promoteStagedQueueToNowPlaying(itemToPlay, restoreFullState: false)
        musicPlayer.nowPlayingItem = itemToPlay as! MPMediaItem
        musicPlayer.play()
        playbackStateManager.correctPlaybackState()
    }
    
    func clearUpcomingItems(#fromIndex:Int) {
        var queue = nowPlayingQueue
        
        
        Logger.debug("clearing now playing queue from index \(fromIndex)")
        queue.removeRange(Range<Int>(start: fromIndex + 1, end: queue.count))
        
        let playbackState = getPlaybackState()
        let mediaItemToPlay = queue[fromIndex]
        setQueueInternal(queue, itemToPlay: mediaItemToPlay)
        if(mediaItemToPlay.id == playbackState.nowPlayingItem!.id) {
            restorePlaybackState(playbackState, override: false, restoreFullState: true)
        }
    }
    
    func deleteItemsAtIndices(indiciesToRemove:[Int]) {
        var indicies = indiciesToRemove
        if(indicies.count > 1) {
            //if removing more than 1 element, sort the array otherwise we will run into index out of bounds issues
            indicies.sort { $0 > $1 }
        }
        
        var queue = nowPlayingQueue
        var nowPlayingItemRemoved = false
        for index in indicies {
            queue.removeAtIndex(index)
            if (index == indexOfNowPlayingItem) {
                nowPlayingItemRemoved = true
            }
        }
        
        if(nowPlayingItemRemoved) {
            setNowPlayingQueue(MPMediaItemCollection(items: queue), itemToPlay: queue[0])
        }
        
        let playbackState = getPlaybackState()
        setQueueInternal(queue, itemToPlay: nil)
        restorePlaybackState(playbackState, override: false, restoreFullState: true)
        evaluateNextStagedMediaItem(playbackState)
    }
    
    func moveMediaItem(#fromIndexPath:Int, toIndexPath:Int) {
        var queue = nowPlayingQueue
        
        if(fromIndexPath > (queue.count - 1) || toIndexPath > (queue.count - 1)) {
            return
        }
        
        let playbackState = getPlaybackState()
        let mediaItem = queue[fromIndexPath]
        queue.removeAtIndex(fromIndexPath)
        queue.insert(mediaItem, atIndex: toIndexPath)
        setQueueInternal(queue, itemToPlay: playbackState.nowPlayingItem)
        restorePlaybackState(playbackState, override: false, restoreFullState: true)
        evaluateNextStagedMediaItem(playbackState)
    }
    
    func insertItemsAtIndex(itemsToInsert: [AudioTrack], index: Int) {
        var queue = nowPlayingQueue
        var playbackState = getPlaybackState()
        queue.insertAtIndex(itemsToInsert, index: index, placeHolderItem: MPMediaItem())
        setQueueInternal(queue, itemToPlay: playbackState.nowPlayingItem)
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
                let song = (query.items as! [AudioTrack])[0]
                message += song.trackTitle + ", Artist: " + song.albumArtist
            }
        }
        Logger.debug(message)
        promoteStagedQueueToNowPlaying(nextStagedMediaItem, restoreFullState: false)
        AudioQueuePlayerNotificationPublisher.publishNotification(updateType: .NowPlayingItemChanged, sender:self)
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
        AudioQueuePlayerNotificationPublisher.publishNotification(updateType: .PlaybackStateUpdate, sender:self)
    }
    
    func handleApplicationDidResignActive(notification:NSNotification) {
        promoteStagedQueueWithCurrentNowPlayingItem()
    }
    
    private func stagedQueueIsEmpty() -> Bool {
        return (stagedQueue.isEmpty)
    }
    
    private func promoteStagedQueueWithCurrentNowPlayingItem() {
        self.promoteStagedQueueToNowPlaying(musicPlayer.nowPlayingItem, restoreFullState: true)
    }
    
    private func setQueueInternal(mediaItems:[AudioTrack], itemToPlay:AudioTrack?) {
        if(playbackStateManager.musicIsPlaying() || playbackStateManager.otherMusicIsPlaying()) {
            Logger.debug("Setting staged queue")
            stagedQueue = mediaItems
        } else {
            setNowPlayingQueue(MPMediaItemCollection(items: mediaItems as! [MPMediaItem] ), itemToPlay: itemToPlay)
        }
    }
    
    private func setNowPlayingQueue(mediaCollection:MPMediaItemCollection, itemToPlay:AudioTrack?) {
        if(mediaCollection.items != nil) {
            Logger.debug("Setting now playing queue")
            
            persistedQueue = mediaCollection.items as! [AudioTrack]
            musicPlayer.setQueueWithItemCollection(mediaCollection)
            if(itemToPlay != nil) {
                musicPlayer.nowPlayingItem = itemToPlay! as! MPMediaItem
            }
        }
    }
    
    private func resetAllStagedObjects() {
        stagedQueue.removeAll(keepCapacity: false)
        nextStagedMediaItem = nil
        indexOfNextStagedItemExceedsNowPlayingQueueLength = false
    }
    
    private func evaluateNextStagedMediaItem(playbackState: PlaybackStateDTO) {
        if(playbackState.nowPlayingItem == nil || stagedQueueIsEmpty()) {
            return
        }
        
        let unwrappedMediaItem = playbackState.nowPlayingItem!
        let unwrappedQueue = nowPlayingQueue
        for var i=0 ; i<unwrappedQueue.count ; i++ {
            if(unwrappedMediaItem.id == unwrappedQueue[i].id) {
                if(i >= (nowPlayingQueue.count - 1) && i >= playbackState.nowPlayingIndex!) {
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
    
    private func promoteStagedQueueToNowPlaying(itemToPlay:AudioTrack?, restoreFullState:Bool) {
        if(stagedQueueIsEmpty()) {
            return
        }
        Logger.debug("PROMOTING STAGED QUEUE")
        let playbackState = getPlaybackState()
        setNowPlayingQueue(MPMediaItemCollection(items: stagedQueue as! [MPMediaItem]), itemToPlay: itemToPlay)
        
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
            musicPlayer.nowPlayingItem = originalPlaybackState.nowPlayingItem as! MPMediaItem
            musicPlayer.currentPlaybackTime = originalPlaybackState.currentPlaybackTime!
        }
        
        if(originalPlaybackState.musicIsPlaying || indexOfNextStagedItemExceedsNowPlayingQueueLength) {
            musicPlayer.play()
        }
    }
    
    private var observationContext:Int8 = 123
    
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
        
        musicPlayer.addObserver(self, forKeyPath: "nowPlayingItem", options: NSKeyValueObservingOptions.New, context: &observationContext)
        musicPlayer.addObserver(self, forKeyPath: "indexOfNowPlayingItem", options: NSKeyValueObservingOptions.New, context: &observationContext)
        
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        let application = UIApplication.sharedApplication()
        notificationCenter.addObserver(self, selector: "handleApplicationDidResignActive:",
            name: UIApplicationWillResignActiveNotification, object: application)
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        Logger.debug("keyPath:\(keyPath) has changed to \(change)")
    }
    
    private func unregisterForMediaPlayerNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self)
    }
    
//    private func registerForRemoteCommands() {
//        let remoteCommandCenter = MPRemoteCommandCenter.sharedCommandCenter()
//        remoteCommandCenter.playCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            self.play()
//            return MPRemoteCommandHandlerStatus.Success
//        }
//        remoteCommandCenter.pauseCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            self.pause()
//            return MPRemoteCommandHandlerStatus.Success
//        }
//        remoteCommandCenter.togglePlayPauseCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            if(self.musicIsPlaying) {
//                self.pause()
//            } else {
//                self.play()
//            }
//            return MPRemoteCommandHandlerStatus.Success
//        }
//        remoteCommandCenter.previousTrackCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            self.skipBackwards()
//            return MPRemoteCommandHandlerStatus.Success
//        }
//        remoteCommandCenter.nextTrackCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            self.skipForwards()
//            return MPRemoteCommandHandlerStatus.Success
//        }
//    }
//    private func unregisterForRemoteCommands() {
//        let remoteCommandCenter = MPRemoteCommandCenter.sharedCommandCenter()
//        remoteCommandCenter.playCommand.removeTarget(self)
//        remoteCommandCenter.pauseCommand.removeTarget(self)
//        remoteCommandCenter.togglePlayPauseCommand.removeTarget(self)
//        remoteCommandCenter.previousTrackCommand.removeTarget(self)
//        remoteCommandCenter.nextTrackCommand.removeTarget(self)
//    }
    
}