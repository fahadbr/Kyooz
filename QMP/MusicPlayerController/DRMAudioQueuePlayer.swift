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
    
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer()
    private let playbackStateManager:PlaybackStateManager
    private let playCountIterator = PlayCountIterator()
    
    private var queueStateInconsistent:Bool = false {
        didSet {
            if queueStateInconsistent && nowPlayingQueue.count > 0 {
                KyoozUtils.doInMainQueueAsync() {
                    RootViewController.instance.presentWarningView("Kyooz is out of sync with the system music player. Play a new track or Tap to fix!", handler: { () -> () in
                        let vc = UIStoryboard.systemQueueResyncWorkflowController()
                        vc.completionBlock = self.resyncWithSystemQueueUsingIndex
                        ContainerViewController.instance.presentViewController(vc, animated: true, completion: nil)
                    })
                }
            } else {
                KyoozUtils.doInMainQueueAsync() {
                    RootViewController.instance.dismissWarningView()
                }
            }
        }
    }

    
    private var nowPlayingQueueContext:NowPlayingQueueContext {
        didSet {
            publishNotification(updateType: .QueueUpdate, sender: self)
        }
    }
    
    private let lowestIndexPersistedKey = "lowestIndexPersistedKey"
    private var lowestIndexPersisted:Int = 0 {
        didSet {
            TempDataDAO.instance.addPersistentValue(key: lowestIndexPersistedKey, value: NSNumber(integer: lowestIndexPersisted))
        }
    }
    
    override init() {
        playbackStateManager = PlaybackStateManager(musicPlayer: musicPlayer)
        if let nowPlayingQueueContext = TempDataDAO.instance.getPlaybackStateSnapshotFromTempStorage()?.nowPlayingQueueContext {
            self.nowPlayingQueueContext = nowPlayingQueueContext
        } else {
            Logger.error("couldnt get queue from temp storage. starting with empty queue")
            nowPlayingQueueContext = NowPlayingQueueContext(originalQueue: [AudioTrack](), forType: type)
        }
        
        if let indexBeforeMod = TempDataDAO.instance.getPersistentValue(key: lowestIndexPersistedKey) as? NSNumber {
            lowestIndexPersisted = indexBeforeMod.longValue
        }
        
        super.init()
        registerForMediaPlayerNotifications()
    }
    
    deinit {
        unregisterForMediaPlayerNotifications()
    }

    
    //MARK: AudioQueuePlayer - Properties
    var type = AudioQueuePlayerType.AppleDRM
    
	var playbackStateSnapshot:PlaybackStateSnapshot {
		get {
			return PlaybackStateSnapshot(nowPlayingQueueContext: nowPlayingQueueContext, currentPlaybackTime: currentPlaybackTime)
		} set(newSnapshot) {
            let musicWasPlaying = musicIsPlaying
			musicPlayer.stop()
			guard let items = newSnapshot.nowPlayingQueueContext.currentQueue as? [MPMediaItem] else {
				Logger.error("trying to restore a queue with objects that are not MPMediaItem")
				return
			}
			nowPlayingQueueContext = newSnapshot.nowPlayingQueueContext
			playNowInternal(items, index: nowPlayingQueueContext.indexOfNowPlayingItem, shouldPlay: false)
			currentPlaybackTime = newSnapshot.currentPlaybackTime
            if musicWasPlaying {
                play()
            }
		}
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
    
    private (set) var indexOfNowPlayingItem:Int {
        get {
            return nowPlayingQueueContext.indexOfNowPlayingItem
        } set {
            nowPlayingQueueContext.indexOfNowPlayingItem = newValue
        }
    }
    
    var shuffleActive:Bool {
        get {
            return nowPlayingQueueContext.shuffleActive && nowPlayingItem != nil
        } set {
            nowPlayingQueueContext.setShuffleActive(newValue)
            persistToSystemQueue(nowPlayingQueueContext)
            publishNotification(updateType: .SystematicQueueUpdate, sender: self)
        }
    }
    
    var repeatMode:RepeatState {
        get {
            if nowPlayingItem == nil {
                return .Off
            }
            
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
            switch(newValue) {
            case .Off:
                musicPlayer.repeatMode = .None
                persistToSystemQueue(nowPlayingQueueContext)
            case .One:
                musicPlayer.repeatMode = .One
            case .All:
                musicPlayer.repeatMode = .All
                persistToSystemQueue(nowPlayingQueueContext)
            }
            publishNotification(updateType: .SystematicQueueUpdate, sender: self)
        }
    }
    
    var delegate:AudioQueuePlayerDelegate?
    
    //MARK: AudioQueuePlayer - Functions
    
    func play() {
        musicPlayer.play()
        playbackStateManager.correctPlaybackState()
    }
    
    func pause() {
        musicPlayer.pause()
        playbackStateManager.correctPlaybackState()
    }
    
    func skipForwards() {
        musicPlayer.skipToNextItem()
        playbackStateManager.correctPlaybackState()
    }
    
    func skipBackwards() {
        if(currentPlaybackTime > 2.0) {
            musicPlayer.skipToBeginning()
        } else if lowestIndexPersisted > 0 {
            playNowInternal(nowPlayingQueue as! [MPMediaItem], index: indexOfNowPlayingItem - 1, shouldPlay: musicIsPlaying)
        } else {
            musicPlayer.skipToPreviousItem()
        }
        playbackStateManager.correctPlaybackState()
    }
    
    func playNow(withTracks tracks:[AudioTrack], startingAtIndex index:Int, shouldShuffleIfOff:Bool) {
        KyoozUtils.doInMainQueueAsync() {
			let oldSnapshot = self.playbackStateSnapshot
			
            var newContext = NowPlayingQueueContext(originalQueue: tracks, forType: self.type)
            newContext.indexOfNowPlayingItem = index >= tracks.count ? 0 : index
            newContext.setShuffleActive(self.shuffleActive || shouldShuffleIfOff)
            
            guard let mediaItems = newContext.currentQueue as? [MPMediaItem] else {
                Logger.error("DRM audio player cannot play tracks that are not MPMediaItem objects")
                return
            }
            
            self.nowPlayingQueueContext = newContext
            self.playNowInternal(mediaItems, index: newContext.indexOfNowPlayingItem)
			
			self.delegate?.audioQueuePlayerDidChangeContext(self, previousSnapshot:oldSnapshot)
        }
        
    }
    
    func playItemWithIndexInCurrentQueue(index index:Int) {
        if nowPlayingItem == nil || lowestIndexPersisted > 0 || queueStateInconsistent {
            playNowInternal(nowPlayingQueue as! [MPMediaItem], index: index)
            return
        }
        if let newItem = nowPlayingQueue[index] as? MPMediaItem {
            musicPlayer.nowPlayingItem = newItem
            if !musicIsPlaying {
                musicPlayer.play()
            }
        }
    }
    
    func enqueue(items itemsToEnqueue:[AudioTrack], atPosition position:EnqueuePosition) {
        let oldContext = nowPlayingQueueContext
        nowPlayingQueueContext.enqueue(items: itemsToEnqueue, atPosition: position)
        persistToSystemQueue(oldContext)
		delegate?.audioQueuePlayerDidEnqueueItems(itemsToEnqueue, position: position)
    }
    
    func insertItemsAtIndex(itemsToInsert:[AudioTrack], index:Int) -> Int {
        let oldContext = nowPlayingQueueContext
        nowPlayingQueueContext.insertItemsAtIndex(itemsToInsert, index: index)
        persistToSystemQueue(oldContext)
        return itemsToInsert.count
    }
    
    func deleteItemsAtIndices(indiciesToRemove:[Int]) {
        let oldContext = nowPlayingQueueContext
        let nowPlayingItemRemoved = nowPlayingQueueContext.deleteItemsAtIndices(indiciesToRemove)
        if nowPlayingItemRemoved {
            resetQueueStateToBeginning()
        } else {
            persistToSystemQueue(oldContext)
        }
    }
    
    func moveMediaItem(fromIndexPath fromIndexPath:Int, toIndexPath:Int) {
        let oldContext = nowPlayingQueueContext
        nowPlayingQueueContext.moveMediaItem(fromIndexPath: fromIndexPath, toIndexPath: toIndexPath)
        persistToSystemQueue(oldContext)
    }
    
    func clearItems(towardsDirection direction:ClearDirection, atIndex index:Int) {
        let oldContext = nowPlayingQueueContext
        let nowPlayingItemRemoved = nowPlayingQueueContext.clearItems(towardsDirection: direction, atIndex: index)
        if nowPlayingItemRemoved {
            resetQueueStateToBeginning()
        } else {
            persistToSystemQueue(oldContext)
        }
    }
    
    //MARK: - Class functions
    
	private func playNowInternal(mediaItems:[MPMediaItem], index:Int, shouldPlay:Bool = true) {
        musicPlayer.setQueueWithItemCollection(MPMediaItemCollection(items: mediaItems))
        musicPlayer.nowPlayingItem = mediaItems[index]
		if shouldPlay {
			musicPlayer.play()
		}
        playbackStateManager.correctPlaybackState()
        
        queueStateInconsistent = false
        lowestIndexPersisted = 0
        refreshIndexOfNowPlayingItem()
    }
    
    private func persistToSystemQueue(oldContext:NowPlayingQueueContext) {
        if queueStateInconsistent {
            queueStateInconsistent = true //doing this to retrigger the warning view if its not currently showing
            Logger.debug("queue state is inconsistent. will not persist changes")
            return
        }
        
        guard let queue = nowPlayingQueue as? [MPMediaItem]  else {
            Logger.error("Now playing queue is not one that contains MPMediaItem objects.  Cannot persist to queue")
            return
        }
        
        lowestIndexPersisted = indexOfNowPlayingItem
        var truncatedQueue = [MPMediaItem]()
        let repeatAllEnabled = repeatMode == .All
        truncatedQueue.reserveCapacity(repeatAllEnabled ? queue.count : queue.count - indexOfNowPlayingItem)
        for i in indexOfNowPlayingItem..<queue.count {
            truncatedQueue.append(queue[i])
        }
        
        if repeatAllEnabled {
            for i in 0 ..< indexOfNowPlayingItem {
                truncatedQueue.append(queue[i])
            }
        }
        
//        KyoozUtils.doInMainQueueAsync() { [musicPlayer = self.musicPlayer] in
            musicPlayer.setQueueWithItemCollection(MPMediaItemCollection(items: truncatedQueue))
            let item = musicPlayer.nowPlayingItem //only doing this because compiler wont allow assigning an object to itself directly
            musicPlayer.nowPlayingItem = item //need to invoke the setter so that the queue changes take place
//        }
		
        presentNotificationsIfNecessary()
    }
    
    private func resetQueueStateToBeginning() {
        if queueStateInconsistent {
            return
        }
        
        if nowPlayingQueue.isEmpty {
            musicPlayer.stop()
            return
        }
        
        nowPlayingQueueContext.indexOfNowPlayingItem = 0
        lowestIndexPersisted = 0
        queueStateInconsistent = false
        musicPlayer.setQueueWithItemCollection(MPMediaItemCollection(items: nowPlayingQueue as! [MPMediaItem]))
        musicPlayer.nowPlayingItem = nowPlayingQueue[indexOfNowPlayingItem] as? MPMediaItem
        playbackStateManager.correctPlaybackState()

    }
    
    private func refreshIndexOfNowPlayingItem() {
        guard let nowPlayingItem = self.nowPlayingItem else {
            resetQueueStateToBeginning()
            return
        }
        
        let i = musicPlayer.indexOfNowPlayingItem + lowestIndexPersisted
        let count = nowPlayingQueue.count
        let newIndex = count == 0 ? i : i%nowPlayingQueue.count
        
        if newIndex >= count || nowPlayingQueue[newIndex].id != nowPlayingItem.id {
            queueStateInconsistent = true
            indexOfNowPlayingItem = 0
        } else {
            indexOfNowPlayingItem = newIndex
        }
    }
    
    private func resyncWithSystemQueueUsingIndex(indexOfNewItem index:Int) {
        guard let itemToPlay = nowPlayingItem else {
            resetQueueStateToBeginning()
            return
        }
        let queue = nowPlayingQueue
        guard index < queue.count else {
            Logger.error("trying to play an index that is out of bounds")
            return
        }
        
        queueStateInconsistent = false
        let oldContext = nowPlayingQueueContext
        if itemToPlay.id != queue[index].id {
            nowPlayingQueueContext.insertItemsAtIndex([itemToPlay], index: index)
        }
        indexOfNowPlayingItem = index
        persistToSystemQueue(oldContext)
        playbackStateManager.correctPlaybackState()
    }
    
    
    //MARK: - Notification handling functions
    
    func handleNowPlayingItemChanged(notification:NSNotification) {
        refreshIndexOfNowPlayingItem()
        publishNotification(updateType: .NowPlayingItemChanged, sender: self)
    }
    
    func handlePlaybackStateChanged(notification:NSNotification) {
        publishNotification(updateType: .PlaybackStateUpdate, sender: self)
    }
    
    func handleApplicationDidResignActive(notification:NSNotification) {
        
    }
    
    func handleApplicationDidBecomeActive(notification:NSNotification) {
        playbackStateManager.correctPlaybackState()
        refreshIndexOfNowPlayingItem()
        if musicPlayer.shuffleMode != .Off && nowPlayingItem != nil {
            let ac = UIAlertController(title: "Do you want to turn on Shuffle in Kyooz?", message: "Kyooz has noticed that you turned on shuffle mode in the system music player.  Would you like to use the shuffle mode in Kyooz instead?  Using the shuffle mode in Kyooz allows you to queue up items within the app however you like", preferredStyle: .Alert)
            let turnOnShuffleAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.musicPlayer.shuffleMode = .Off
                self.shuffleActive = true
            })
            ac.addAction(turnOnShuffleAction)
            ac.preferredAction = turnOnShuffleAction
            ac.addAction(UIAlertAction(title: "No", style: .Cancel, handler: nil))
            ContainerViewController.instance.presentViewController(ac, animated: true, completion: nil)
        }
    }
    
    func handleApplicationWillTerminate(notification:NSNotification) {
        
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
    
}