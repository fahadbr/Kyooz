//
//  ApplicationAudioQueuePlayer.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/1/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer
import Foundation

private let outOfSyncMessage = "Another app is using the iOS music player! Play a new track or Tap to fix!"
@available(iOS 10.3, *)
final class ApplicationAudioQueuePlayer: NSObject, AudioQueuePlayer {
    static let instance = ApplicationAudioQueuePlayer()
    
    private let musicPlayer = MPMusicPlayerController.applicationQueuePlayer
    private let playbackStateManager:PlaybackStateManager
    private let playCountIterator = PlayCountIterator()
    private let nowPlayingInfoHelper = NowPlayingInfoHelper.instance

    
    private var playQueue:PlayQueue {
        didSet {
            publishNotification(for: .queueUpdate)
        }
    }
    
    private let lowestIndexPersistedKey = "lowestIndexPersistedKey"
    private (set) var lowestIndexPersisted:Int = 0 {
        didSet {
            TempDataDAO.instance.addPersistentValue(key: lowestIndexPersistedKey, value: NSNumber(value: lowestIndexPersisted))
        }
    }
    
    override init() {
        playbackStateManager = PlaybackStateManager(musicPlayer: musicPlayer)
        if let playQueue = TempDataDAO.instance.getPlaybackStateSnapshotFromTempStorage()?.playQueue {
            self.playQueue = playQueue
        } else {
            Logger.error("couldnt get queue from temp storage. starting with empty queue")
            playQueue = PlayQueue(originalQueue: [AudioTrack](), forType: type)
        }
        
        if let indexBeforeMod = TempDataDAO.instance.getPersistentValue(key: lowestIndexPersistedKey) as? NSNumber {
            lowestIndexPersisted = indexBeforeMod.intValue
        }

//        AudioSessionManager.instance.initializeAudioSession()

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
			return PlaybackStateSnapshot(playQueue: playQueue, currentPlaybackTime: currentPlaybackTime)
		} set(newSnapshot) {
            let musicWasPlaying = musicIsPlaying
			musicPlayer.stop()
			guard let items = newSnapshot.playQueue.currentQueue as? [MPMediaItem] else {
				Logger.error("trying to restore a queue with objects that are not MPMediaItem")
				return
			}
			playQueue = newSnapshot.playQueue
			playNowInternal(items, index: playQueue.indexOfNowPlayingItem, shouldPlay: false)
			currentPlaybackTime = newSnapshot.currentPlaybackTime
            if musicWasPlaying {
                play()
            }
		}
    }
    
    var nowPlayingQueue:[AudioTrack] {
        return playQueue.currentQueue
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
            return playQueue.indexOfNowPlayingItem
        } set {
            playQueue.indexOfNowPlayingItem = newValue
        }
    }
    
    var shuffleActive:Bool {
        get {
            return playQueue.shuffleActive && nowPlayingItem != nil
        } set {
            playQueue.setShuffleActive(newValue)
            persistToSystemQueue(playQueue)
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
                persistToSystemQueue(playQueue)
            case .one:
                musicPlayer.repeatMode = .one
            case .all:
                musicPlayer.repeatMode = .all
                persistToSystemQueue(playQueue)
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
        } else if lowestIndexPersisted > 0  {
            playNowInternal(nowPlayingQueue as! [MPMediaItem], index: indexOfNowPlayingItem - 1, shouldPlay: musicIsPlaying)
        } else {
            musicPlayer.skipToPreviousItem()
        }
        playbackStateManager.correctPlaybackState()
    }
    
    func playNow(withTracks tracks:[AudioTrack], startingAtIndex index:Int, shouldShuffleIfOff:Bool) {
        KyoozUtils.doInMainQueueAsync() {
			let oldSnapshot = self.playbackStateSnapshot
			
            var newPlayQueue = PlayQueue(originalQueue: tracks, forType: self.type)
            newPlayQueue.indexOfNowPlayingItem = index >= tracks.count ? 0 : index
            newPlayQueue.setShuffleActive(self.shuffleActive || shouldShuffleIfOff)
            
            guard let mediaItems = newPlayQueue.currentQueue as? [MPMediaItem] else {
                Logger.error("DRM audio player cannot play tracks that are not MPMediaItem objects")
                return
            }
            
            self.playQueue = newPlayQueue
            self.playNowInternal(mediaItems, index: newPlayQueue.indexOfNowPlayingItem)
			
			self.delegate?.audioQueuePlayerDidChangeContext(self, previousSnapshot:oldSnapshot)
        }
        
    }
    
    func playTrack(at index: Int) {
        if nowPlayingItem == nil || lowestIndexPersisted > 0 {
            playNowInternal(nowPlayingQueue as! [MPMediaItem], index: index)
            return
        }
        if let newItem = nowPlayingQueue[index] as? MPMediaItem {
            musicPlayer.nowPlayingItem = newItem
            if !musicIsPlaying {
                musicPlayer.prepareToPlay(completionHandler: { _ in
                    self.musicPlayer.play()
                })
            }
        }
    }
    
    func enqueue(tracks tracksToEnqueue: [AudioTrack], at enqueueAction: EnqueueAction) {
//        let oldContext = playQueue
        playQueue.enqueue(items: tracksToEnqueue, at: enqueueAction)
//        persistToSystemQueue(oldContext)
        let mediaItems = tracksToEnqueue as! [MPMediaItem]
        musicPlayer.append(MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: mediaItems)))

		delegate?.audioQueuePlayerDidEnqueueItems(tracks: tracksToEnqueue, at: enqueueAction)
    }
    
    func insert(tracks tracksToInsert: [AudioTrack], at index: Int) -> Int {
        let oldContext = playQueue
        playQueue.insertItemsAtIndex(tracksToInsert, index: index)
        let mediaItems = tracksToInsert as! [MPMediaItem]
        let mediaItem = oldContext.currentQueue[index - 1] as! MPMediaItem
        musicPlayer.perform(queueTransaction: { (queue) in
            queue.insert((MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: mediaItems))), after: mediaItem)
        }, completionHandler: {_, error in
            if let e = error {
                Logger.error(e.description)
            }
        })
//        persistToSystemQueue(oldContext)
        return tracksToInsert.count
    }
    
    func delete(at indicies: [Int]) {
        let oldContext = playQueue
        let nowPlayingItemRemoved = playQueue.deleteItemsAtIndices(indicies)
        if nowPlayingItemRemoved {
            resetQueueStateToBeginning()
        } else {
            musicPlayer.perform(queueTransaction: { (queue) in
                for index in indicies {
                    queue.remove(oldContext.currentQueue[index] as! MPMediaItem)
                }

            }, completionHandler: {_, _ in })
        }
    }
    
    func move(from sourceIndex: Int, to destinationIndex: Int) {
        let oldContext = playQueue
        playQueue.moveMediaItem(fromIndexPath: sourceIndex, toIndexPath: destinationIndex)
        let fromItem = oldContext.currentQueue[sourceIndex] as! MPMediaItem
        let toItem = oldContext.currentQueue[destinationIndex - 1] as! MPMediaItem

//        persistToSystemQueue(oldContext)
        musicPlayer.perform(queueTransaction: { (queue) in
            queue.remove(fromItem)
            queue.insert(MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: [fromItem])), after: toItem)
            
        }, completionHandler: {_, _ in })
    }
    
    func clear(from direction: ClearDirection, at index: Int) {
        let oldContext = playQueue
        let nowPlayingItemRemoved = playQueue.clearItems(towardsDirection: direction, atIndex: index)
        if nowPlayingItemRemoved {
            resetQueueStateToBeginning()
        } else {
//            persistToSystemQueue(oldContext)
            musicPlayer.perform(queueTransaction: { (queue) in
                if direction == .above || direction == .bothDirections {
                    for i in 0..<index {
                        queue.remove(oldContext.currentQueue[i] as! MPMediaItem)
                    }
                }
                if direction == .below || direction == .bothDirections {
                    for i in index..<oldContext.currentQueue.count {
                        queue.remove(oldContext.currentQueue[i] as! MPMediaItem)
                    }
                }
            }, completionHandler: {_, _ in })
        }
    }
    
    //MARK: - Class functions
    
	private func playNowInternal(_ mediaItems:[MPMediaItem], index:Int, shouldPlay:Bool = true) {
        guard index >= 0 else {
            resetQueueStateToBeginning()
            return
        }
        
        musicPlayer.setQueue(with: MPMediaItemCollection(items: mediaItems))
        let newItem = mediaItems[index]
        musicPlayer.nowPlayingItem = newItem
		if shouldPlay {
            musicPlayer.prepareToPlay(completionHandler: { _ in
                self.musicPlayer.play()
//                self.nowPlayingInfoHelper.publishNowPlayingInfo(newItem, currentIndex: index, queueCount: mediaItems.count)
            })
		}
        playbackStateManager.correctPlaybackState()

        lowestIndexPersisted = 0
        refreshIndexOfNowPlayingItem()
    }
    
    private func persistToSystemQueue(_ oldContext:PlayQueue) {
        
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
        
        if nowPlayingQueue.isEmpty {
            musicPlayer.stop()
            return
        }
        
        playQueue.indexOfNowPlayingItem = 0
        lowestIndexPersisted = 0
        musicPlayer.setQueue(with: MPMediaItemCollection(items: nowPlayingQueue as! [MPMediaItem]))
        musicPlayer.nowPlayingItem = nowPlayingQueue[indexOfNowPlayingItem] as? MPMediaItem
        playbackStateManager.correctPlaybackState()

    }
    
    private func refreshIndexOfNowPlayingItem() {
        guard let nowPlayingItem = self.nowPlayingItem else {
            resetQueueStateToBeginning()
            return
        }
        
        let count = nowPlayingQueue.count
        let newIndex = deriveQueueIndex(musicPlayer: musicPlayer,
                                        lowestIndexPersisted: lowestIndexPersisted,
                                        queueSize: count)

        indexOfNowPlayingItem = newIndex
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
        notificationCenter.addObserver(self, selector: #selector(ApplicationAudioQueuePlayer.handleNowPlayingItemChanged(_:)),
            name:NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer)
        notificationCenter.addObserver(self, selector: #selector(ApplicationAudioQueuePlayer.handlePlaybackStateChanged(_:)),
            name:NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer)
        notificationCenter.addObserver(self, selector: #selector(ApplicationAudioQueuePlayer.handlePlaybackStateChanged(_:)),
            name:NSNotification.Name(rawValue: PlaybackStateManager.PlaybackStateCorrectedNotification),
            object: playbackStateManager)
        
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        let application = UIApplication.shared
        notificationCenter.addObserver(self, selector: #selector(ApplicationAudioQueuePlayer.handleApplicationDidResignActive(_:)),
            name: NSNotification.Name.UIApplicationWillResignActive, object: application)
        notificationCenter.addObserver(self, selector: #selector(ApplicationAudioQueuePlayer.handleApplicationDidBecomeActive(_:)),
            name: NSNotification.Name.UIApplicationDidBecomeActive, object: application)
        notificationCenter.addObserver(self, selector: #selector(ApplicationAudioQueuePlayer.handleApplicationWillTerminate(_:)),
            name: NSNotification.Name.UIApplicationWillTerminate, object: application)
        
    }
    
    private func unregisterForMediaPlayerNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }
    
}
