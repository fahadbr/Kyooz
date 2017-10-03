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
    
    private let musicPlayer: MPMusicPlayerApplicationController
    private let playbackStateManager:PlaybackStateManager
    private let playCountIterator = PlayCountIterator()
    private let nowPlayingInfoHelper = NowPlayingInfoHelper.instance
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
    private var playQueue:PlayQueue {
        didSet {
            publishNotification(for: .queueUpdate)
        }
    }
    
    override init() {

        musicPlayer = MPMusicPlayerController.applicationQueuePlayer
        _ = MPMusicPlayerController.systemMusicPlayer

        playbackStateManager = PlaybackStateManager(musicPlayer: musicPlayer)
        if let playQueue = TempDataDAO.instance.getPlaybackStateSnapshotFromTempStorage()?.playQueue {

            self.playQueue = playQueue
        } else {
            Logger.error("couldnt get queue from temp storage. starting with empty queue")
            playQueue = PlayQueue(originalQueue: [AudioTrack](), forType: type)
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
        if nowPlayingItem == nil {
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
        playQueue.enqueue(items: tracksToEnqueue, at: enqueueAction)
        let mediaItems = tracksToEnqueue as! [MPMediaItem]
        let qd = MPMusicPlayerStoreQueueDescriptor(storeIDs: mediaItems.map({ (item) -> String in
            let storeId = item.playbackStoreID
            Logger.debug("storeId is \(storeId)")
            return storeId
        }))
        switch enqueueAction {
        case .last:
            musicPlayer.append(qd)
        case .next:
            musicPlayer.prepend(qd)
        case .random:
            KyoozUtils.showPopupError(
                withTitle: "Unsupported",
                withMessage: "Queueing randomly is currently not supported",
                presentationVC: nil
            )
        }


		delegate?.audioQueuePlayerDidEnqueueItems(tracks: tracksToEnqueue, at: enqueueAction)
    }
    
    func insert(tracks tracksToInsert: [AudioTrack], at index: Int) -> Int {
        let oldContext = playQueue
        playQueue.insertItemsAtIndex(tracksToInsert, index: index)
        let mediaItems = tracksToInsert as! [MPMediaItem]
        musicPlayer.perform(queueTransaction: { (mutableQueue) in
            Logger.debug("performing queue txn with \(mediaItems.count) media items ")

            let qd = MPMusicPlayerStoreQueueDescriptor(storeIDs: mediaItems.map({ (item) -> String in
                let storeId = item.playbackStoreID
                Logger.debug("storeId is \(storeId)")
                return storeId
            }))
            mutableQueue.insert(qd, after: mutableQueue.items[index - 1])

        }, completionHandler: {queue, error in
            if let e = error {
                Logger.error(e.description)
            } else {
                Logger.debug("\(queue.items.count) items after adjustment")
                if queue.items.count != self.playQueue.currentQueue.count {
                    self.playQueue = PlayQueue( originalQueue: queue.items, forType: .appleDRM)
                    self.playQueue.indexOfNowPlayingItem = oldContext.indexOfNowPlayingItem
                }
            }
        })
        return tracksToInsert.count
    }

    private func getQueueDescriptorWrappers(_ mediaItems: [MPMediaItem]) -> [QueueDescriptorWrapper] {
        
    }

    private func performTxn(with queueDescriptors: [QueueDescriptorWrapper], at qdIndex: Int, after queueIndex: Int) {
        if qdIndex >= queueDescriptors.count {
            return
        }

        let qdw = queueDescriptors[qdIndex]
        musicPlayer.perform(queueTransaction: { (mutableQueue) in
            mutableQueue.insert(qdw.queueDescriptor, after: mutableQueue.items[queueIndex - 1])
        }) { (queue, error) in
            if let e = error {
                Logger.error(e.description)
                return
            }
            if queue.items.count != self.playQueue.currentQueue.count {
                Logger.debug("something didnt go right. \(queue.items.count) items after adjustment instead of \(self.nowPlayingQueue.count)")
                self.playQueue = PlayQueue( originalQueue: queue.items, forType: .appleDRM)
                self.playQueue.indexOfNowPlayingItem = self.musicPlayer.indexOfNowPlayingItem
            } else {
                self.performTxn(with: queueDescriptors, at: qdIndex + 1, after: queueIndex + qdw.count)
            }

        }
    }

    private struct QueueDescriptorWrapper {
        let queueDescriptor: MPMusicPlayerQueueDescriptor
        let count: Int
    }
    
    func delete(at indicies: [Int]) {
        let nowPlayingItemRemoved = playQueue.deleteItemsAtIndices(indicies)
        if nowPlayingItemRemoved {
            resetQueueStateToBeginning()
        } else {
            musicPlayer.perform(queueTransaction: { (queue) in
                let indiciesToRemove = indicies.sorted(by: >)
                for index in indiciesToRemove {
                    queue.remove(queue.items[index])
                }

            }, completionHandler: {_, _ in })
        }
    }
    
    func move(from sourceIndex: Int, to destinationIndex: Int) {
        playQueue.moveMediaItem(fromIndexPath: sourceIndex, toIndexPath: destinationIndex)

        musicPlayer.perform(queueTransaction: { (queue) in
            let mediaItemToMove = queue.items[sourceIndex]
            let toItem = queue.items[destinationIndex]
            queue.remove(mediaItemToMove)
            let qd = MPMusicPlayerStoreQueueDescriptor(storeIDs: [mediaItemToMove.playbackStoreID])
            queue.insert(qd, after: toItem)
            
        }, completionHandler: {_, _ in })
    }
    
    func clear(from direction: ClearDirection, at index: Int) {
        let oldContext = playQueue
        let ionpi = self.indexOfNowPlayingItem
        let nowPlayingItemRemoved = playQueue.clearItems(towardsDirection: direction, atIndex: index)
        if nowPlayingItemRemoved {
            resetQueueStateToBeginning()
        } else {
            musicPlayer.perform(queueTransaction: { (queue) in
                if direction == .below || direction == .bothDirections {
                    for i in (index..<oldContext.currentQueue.count).reversed() {
                        guard i != ionpi else { continue }

                        queue.remove(queue.items[i])
                    }
                }
                if direction == .above || direction == .bothDirections {
                    for i in (0..<index).reversed() {
                        guard i != ionpi else { continue }
                        queue.remove(queue.items[i])
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
            })
		}
        playbackStateManager.correctPlaybackState()

        refreshIndexOfNowPlayingItem()
    }
    
    private func persistToSystemQueue(_ oldContext:PlayQueue) {
        
        guard let queue = nowPlayingQueue as? [MPMediaItem]  else {
            Logger.error("Now playing queue is not one that contains MPMediaItem objects.  Cannot persist to queue")
            return
        }

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
        musicPlayer.setQueue(with: MPMediaItemCollection(items: nowPlayingQueue as! [MPMediaItem]))
        musicPlayer.nowPlayingItem = nowPlayingQueue[indexOfNowPlayingItem] as? MPMediaItem
        playbackStateManager.correctPlaybackState()

    }
    
    private func refreshIndexOfNowPlayingItem() {
        guard self.nowPlayingItem != nil else {
            resetQueueStateToBeginning()
            return
        }

        indexOfNowPlayingItem = musicPlayer.indexOfNowPlayingItem
    }

    
    
    //MARK: - Notification handling functions
    
    @objc func handleNowPlayingItemChanged(_ notification:Notification) {
        refreshIndexOfNowPlayingItem()
        publishNotification(for: .nowPlayingItemChanged)
    }
    
    @objc func handlePlaybackStateChanged(_ notification:Notification) {
        publishNotification(for: .playbackStateUpdate)
    }
    
    @objc func handleApplicationDidResignActive(_ notification:Notification) {
        
    }
    
    @objc func handleApplicationDidBecomeActive(_ notification:Notification) {
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

        musicPlayer.perform(queueTransaction: { _ in
            //no op
        }) { (queue, _) in
            let audioTracks: [AudioTrack] = queue.items
            var newPlayQueue = PlayQueue(originalQueue: audioTracks, forType: self.type)
            newPlayQueue.indexOfNowPlayingItem = self.musicPlayer.indexOfNowPlayingItem
            self.playQueue = newPlayQueue
        }
    }
    
    @objc func handleApplicationWillTerminate(_ notification:Notification) {
        
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
