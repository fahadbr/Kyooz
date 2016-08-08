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

private let outOfSyncMessage = "Another app is using the iOS music player! Play a new track or Tap to fix!"
final class DRMAudioQueuePlayer: NSObject, AudioQueuePlayer {
    static let instance = DRMAudioQueuePlayer()
    
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer()
    private let playbackStateManager:PlaybackStateManager
    private let playCountIterator = PlayCountIterator()
    
    private var queueStateInconsistent:Bool = false {
        didSet {
            if queueStateInconsistent && nowPlayingQueue.count > 0 {
                KyoozUtils.doInMainQueueAsync() {
                    RootViewController.instance.presentWarningView(outOfSyncMessage, handler: { () -> () in
                        let vc = UIStoryboard.systemQueueResyncWorkflowController()
                        vc.completionBlock = self.resyncWithSystemQueueUsingIndex
                        ContainerViewController.instance.present(vc, animated: true, completion: nil)
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
            publishNotification(for: .queueUpdate)
        }
    }
    
    private let lowestIndexPersistedKey = "lowestIndexPersistedKey"
    private var lowestIndexPersisted:Int = 0 {
        didSet {
            TempDataDAO.instance.addPersistentValue(key: lowestIndexPersistedKey, value: NSNumber(value: lowestIndexPersisted))
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
            lowestIndexPersisted = indexBeforeMod.intValue
        }
        
        super.init()
        registerForMediaPlayerNotifications()
    }
    
    deinit {
        unregisterForMediaPlayerNotifications()
    }

    
    //MARK: AudioQueuePlayer - Properties
    let type = AudioQueuePlayerType.appleDRM
    
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
            if nowPlayingItem != nil {
                if newValue == 0.0 {
                    musicPlayer.skipToBeginning()
                } else {
                    musicPlayer.currentPlaybackTime = TimeInterval(newValue)
                }
                publishNotification(for: .playbackStateUpdate)
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
            publishNotification(for: .systematicQueueUpdate)
        }
    }
    
    var repeatMode:RepeatState {
        get {
            if nowPlayingItem == nil {
                return .off
            }
            
            switch(musicPlayer.repeatMode) {
            case .none:
                return .off
            case .all, .default:
                return .all
            case .one:
                return .one
            }
        }
        set {
            switch(newValue) {
            case .off:
                musicPlayer.repeatMode = .none
                persistToSystemQueue(nowPlayingQueueContext)
            case .one:
                musicPlayer.repeatMode = .one
            case .all:
                musicPlayer.repeatMode = .all
                persistToSystemQueue(nowPlayingQueueContext)
            }
            publishNotification(for: .systematicQueueUpdate)
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
    
    func skipBackwards(_ forcePreviousTrack: Bool) {
        if(currentPlaybackTime > 2.0 && !forcePreviousTrack) {
            currentPlaybackTime = 0.0
        } else if lowestIndexPersisted > 0  && !queueStateInconsistent {
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
    
    func playTrack(at index: Int) {
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
    
    func enqueue(tracks tracksToEnqueue: [AudioTrack], at enqueueAction: EnqueueAction) {
        let oldContext = nowPlayingQueueContext
        nowPlayingQueueContext.enqueue(items: tracksToEnqueue, at: enqueueAction)
        persistToSystemQueue(oldContext)
		delegate?.audioQueuePlayerDidEnqueueItems(tracks: tracksToEnqueue, at: enqueueAction)
    }
    
    func insert(tracks tracksToInsert: [AudioTrack], at index: Int) -> Int {
        let oldContext = nowPlayingQueueContext
        nowPlayingQueueContext.insertItemsAtIndex(tracksToInsert, index: index)
        persistToSystemQueue(oldContext)
        return tracksToInsert.count
    }
    
    func delete(at indicies: [Int]) {
        let oldContext = nowPlayingQueueContext
        let nowPlayingItemRemoved = nowPlayingQueueContext.deleteItemsAtIndices(indicies)
        if nowPlayingItemRemoved {
            resetQueueStateToBeginning()
        } else {
            persistToSystemQueue(oldContext)
        }
    }
    
    func move(from sourceIndex: Int, to destinationIndex: Int) {
        let oldContext = nowPlayingQueueContext
        nowPlayingQueueContext.moveMediaItem(fromIndexPath: sourceIndex, toIndexPath: destinationIndex)
        persistToSystemQueue(oldContext)
    }
    
    func clear(from direction: ClearDirection, at index: Int) {
        let oldContext = nowPlayingQueueContext
        let nowPlayingItemRemoved = nowPlayingQueueContext.clearItems(towardsDirection: direction, atIndex: index)
        if nowPlayingItemRemoved {
            resetQueueStateToBeginning()
        } else {
            persistToSystemQueue(oldContext)
        }
    }
    
    //MARK: - Class functions
    
	private func playNowInternal(_ mediaItems:[MPMediaItem], index:Int, shouldPlay:Bool = true) {
        guard index >= 0 else {
            resetQueueStateToBeginning()
            return
        }
        
        musicPlayer.setQueue(with: MPMediaItemCollection(items: mediaItems))
        musicPlayer.nowPlayingItem = mediaItems[index]
		if shouldPlay {
			musicPlayer.play()
		}
        playbackStateManager.correctPlaybackState()
        
        queueStateInconsistent = false
        lowestIndexPersisted = 0
        refreshIndexOfNowPlayingItem()
    }
    
    private func persistToSystemQueue(_ oldContext:NowPlayingQueueContext) {
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
        let repeatAllEnabled = repeatMode == .all
        truncatedQueue.reserveCapacity(repeatAllEnabled ? queue.count : queue.count - indexOfNowPlayingItem)
        for i in indexOfNowPlayingItem..<queue.count {
            truncatedQueue.append(queue[i])
        }
        
        if repeatAllEnabled {
            for i in 0 ..< indexOfNowPlayingItem {
                truncatedQueue.append(queue[i])
            }
        }
        
        musicPlayer.setQueue(with: MPMediaItemCollection(items: truncatedQueue))
        let item = musicPlayer.nowPlayingItem //only doing this because compiler wont allow assigning an object to itself directly
        musicPlayer.nowPlayingItem = item //need to invoke the setter so that the queue changes take place
		
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
        musicPlayer.setQueue(with: MPMediaItemCollection(items: nowPlayingQueue as! [MPMediaItem]))
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
    
    func handleNowPlayingItemChanged(_ notification:Notification) {
        refreshIndexOfNowPlayingItem()
        publishNotification(for: .nowPlayingItemChanged)
    }
    
    func handlePlaybackStateChanged(_ notification:Notification) {
        publishNotification(for: .playbackStateUpdate)
    }
    
    func handleApplicationDidResignActive(_ notification:Notification) {
        
    }
    
    func handleApplicationDidBecomeActive(_ notification:Notification) {
        playbackStateManager.correctPlaybackState()
        refreshIndexOfNowPlayingItem()
        if musicPlayer.shuffleMode != .off && nowPlayingItem != nil {
            let ac = UIAlertController(title: "Do you want to turn on Shuffle in Kyooz?", message: "Kyooz has noticed that you turned on shuffle mode in the system music player.  Would you like to use the shuffle mode in Kyooz instead?  Using the shuffle mode in Kyooz allows you to queue up items within the app however you like", preferredStyle: .alert)
            let turnOnShuffleAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                self.musicPlayer.shuffleMode = .off
                self.shuffleActive = true
            })
            ac.addAction(turnOnShuffleAction)
            ac.preferredAction = turnOnShuffleAction
            ac.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            ContainerViewController.instance.present(ac, animated: true, completion: nil)
        }
    }
    
    func handleApplicationWillTerminate(_ notification:Notification) {
        
    }
    
    private func registerForMediaPlayerNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(DRMAudioQueuePlayer.handleNowPlayingItemChanged(_:)),
            name:NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer)
        notificationCenter.addObserver(self, selector: #selector(DRMAudioQueuePlayer.handlePlaybackStateChanged(_:)),
            name:NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer)
        notificationCenter.addObserver(self, selector: #selector(DRMAudioQueuePlayer.handlePlaybackStateChanged(_:)),
            name:NSNotification.Name(rawValue: PlaybackStateManager.PlaybackStateCorrectedNotification),
            object: playbackStateManager)
        
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        let application = UIApplication.shared
        notificationCenter.addObserver(self, selector: #selector(DRMAudioQueuePlayer.handleApplicationDidResignActive(_:)),
            name: NSNotification.Name.UIApplicationWillResignActive, object: application)
        notificationCenter.addObserver(self, selector: #selector(DRMAudioQueuePlayer.handleApplicationDidBecomeActive(_:)),
            name: NSNotification.Name.UIApplicationDidBecomeActive, object: application)
        notificationCenter.addObserver(self, selector: #selector(DRMAudioQueuePlayer.handleApplicationWillTerminate(_:)),
            name: NSNotification.Name.UIApplicationWillTerminate, object: application)
        
    }
    
    private func unregisterForMediaPlayerNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }
    
}
