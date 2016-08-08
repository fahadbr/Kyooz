//
//  AudioQueuePlayerController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/16/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer
import AVFoundation

typealias KVOContext=UInt8

final class AudioQueuePlayerImpl: NSObject,AudioQueuePlayer,AudioControllerDelegate {
    
    //MARK: STATIC INSTANCE
    static let instance:AudioQueuePlayerImpl = AudioQueuePlayerImpl()
    
    private static let repeatStateKey = "AudioQueuePlayerImpl.repeatStateKey"
    
    //MARK: Class Properties
    let nowPlayingInfoHelper = NowPlayingInfoHelper.instance
    let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
    var shouldPlayAfterLoading:Bool = false
    let audioController:AudioController = AudioEngineController()
    let lastFmScrobbler = LastFmScrobbler.instance
    
    private var nowPlayingQueueContext = NowPlayingQueueContext(originalQueue: [AudioTrack](), forType: .default) {
        didSet {
            publishNotification(for: .queueUpdate)
        }
    }
    
    private var previousIndex:Int {
        switch repeatMode {
        case .off:
            return indexOfNowPlayingItem - 1
        case .one:
            return indexOfNowPlayingItem
        case .all:
            let index = indexOfNowPlayingItem - 1
            return index < 0 ? (nowPlayingQueue.count - 1) : index
        }
    }
    
    private var nextIndex:Int {
        switch repeatMode {
        case .off:
            return indexOfNowPlayingItem + 1
        case .one:
            return indexOfNowPlayingItem
        case .all:
            let queue = nowPlayingQueue
            if queue.isEmpty {
                return 0
            }
            return (indexOfNowPlayingItem + 1)%queue.count
        }
    }
    
    //MARK: Init/Deinit
    override init() {
        super.init()
        AudioSessionManager.instance.initializeAudioSession()
        
        audioController.delegate = self
        if let snapshot = TempDataDAO.instance.getPlaybackStateSnapshotFromTempStorage() {
            var context = snapshot.nowPlayingQueueContext
            let shuffleQueue:[AudioTrack]?
            if context.shuffleActive {
                shuffleQueue = context.currentQueue
                context.setShuffleActive(false)
            } else {
                shuffleQueue = nil
            }
            
            if let filteredTracks = filter(context.currentQueue, presentUnplayableTracks: shuffleQueue == nil) {
                nowPlayingQueueContext = NowPlayingQueueContext(originalQueue: filteredTracks, forType: type)
            }
            
            if let queue = shuffleQueue, let filteredShuffledQueue = filter(queue) {
                nowPlayingQueueContext.overrideShuffleQueue(filteredShuffledQueue)
            }
            
            KyoozUtils.doInMainQueueAsync() {
                self.updateNowPlayingStateToIndex(context.indexOfNowPlayingItem)
                self.currentPlaybackTime = snapshot.currentPlaybackTime.isNormal ? snapshot.currentPlaybackTime : 0
            }
        }
        
        if let repeatStateRawValue = (TempDataDAO.instance.getPersistentValue(key: AudioQueuePlayerImpl.repeatStateKey) as? NSNumber)?.intValue,
            let repeatState = RepeatState(rawValue: repeatStateRawValue) {
            repeatMode = repeatState
        }

        registerForNotifications()
        registerForRemoteCommands()
    }
    
    deinit {
        unregisterForNotifications()
        unregisterForRemoteCommands()
    }
    
    //MARK: AudioQueuePlayer - Properties
    let type = AudioQueuePlayerType.default
    
    var playbackStateSnapshot:PlaybackStateSnapshot {
		get {
			return PlaybackStateSnapshot(nowPlayingQueueContext: nowPlayingQueueContext, currentPlaybackTime: currentPlaybackTime)
		} set(newSnapshot) {
            let musicWasPlaying = musicIsPlaying
			pause()
			nowPlayingQueueContext = newSnapshot.nowPlayingQueueContext
			shouldPlayAfterLoading = false
			updateNowPlayingStateToIndex(nowPlayingQueueContext.indexOfNowPlayingItem)
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
        willSet {
            if(audioController.canScrobble) {
                lastFmScrobbler.scrobbleMediaItem()
            }
        }
        didSet {
            lastFmScrobbler.mediaItemToScrobble = nowPlayingItem
        }
    }
    
    var musicIsPlaying:Bool = false {
        didSet {
            shouldPlayAfterLoading = musicIsPlaying
            publishNotification(for: .playbackStateUpdate)
            TempDataDAO.instance.persistPlaybackStateSnapshotToTempStorage()
            if nowPlayingItem != nil {
                nowPlayingInfoHelper.updateElapsedPlaybackTime(nowPlayingItem!, elapsedTime: currentPlaybackTime)
            }
            if audioController.canScrobble {
                lastFmScrobbler.scrobbleMediaItem()
            }
        }
    }

    var currentPlaybackTime:Float {
        get {
            return Float(audioController.currentPlaybackTime)
        } set {
            if(audioController.audioTrackIsLoaded) {
				guard let nowPlayingItem = self.nowPlayingItem else {
					return
				}
                audioController.currentPlaybackTime = Double(newValue)
                nowPlayingInfoHelper.updateElapsedPlaybackTime(nowPlayingItem, elapsedTime:newValue)
                publishNotification(for: .playbackStateUpdate)
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
            publishNotification(for: .systematicQueueUpdate)
        }
    }

    var repeatMode:RepeatState = .off {
        didSet {
            TempDataDAO.instance.addPersistentValue(key: AudioQueuePlayerImpl.repeatStateKey, value: NSNumber(value: repeatMode.rawValue))
        }
    }

    var delegate:AudioQueuePlayerDelegate?
    
    //MARK: AudioQueuePlayer - Functions
    
    func play() {
        if audioController.play() {
            musicIsPlaying = true
        }
    }
    
    func pause() {
        if audioController.pause() {
            musicIsPlaying = false
        }
    }
    
    func skipForwards() {
//        LastFmScrobbler.instance.scrobbleMediaItem(nowPlayingItem!)
        updateNowPlayingStateToIndex(nextIndex)
    }
    func skipBackwards(_ forcePreviousTrack: Bool) {
        if(currentPlaybackTime < 2.0 || forcePreviousTrack) {
            updateNowPlayingStateToIndex(previousIndex)
        } else {
            currentPlaybackTime = 0.0
        }
    }
    
    func playNow(withTracks tracks:[AudioTrack], startingAtIndex index:Int, shouldShuffleIfOff:Bool) {
        guard let nowPlayingQueue = filter(tracks) else {
            return
        }
		let oldSnapshot = self.playbackStateSnapshot
		
        var newContext = NowPlayingQueueContext(originalQueue: nowPlayingQueue, forType: type)
        newContext.indexOfNowPlayingItem = index >= nowPlayingQueue.count ? 0 : index
        newContext.setShuffleActive(shuffleActive || shouldShuffleIfOff)
        nowPlayingQueueContext = newContext
        shouldPlayAfterLoading = true
        updateNowPlayingStateToIndex(newContext.indexOfNowPlayingItem)
		
		delegate?.audioQueuePlayerDidChangeContext(self, previousSnapshot:oldSnapshot)
    }
    
    func playTrack(at index: Int) {
        if(index == indexOfNowPlayingItem) {
            return
        }
        shouldPlayAfterLoading = true
        updateNowPlayingStateToIndex(index)
    }
    
    func enqueue(tracks tracksToEnqueue: [AudioTrack], at enqueueAction: EnqueueAction) {
        guard let items = filter(tracksToEnqueue) else {
            return
        }
        nowPlayingQueueContext.enqueue(items: items, at: enqueueAction)
        updateNowPlayingStateToIndex(nowPlayingQueueContext.indexOfNowPlayingItem, shouldLoadAfterUpdate: false)
		presentNotificationsIfNecessary()
        delegate?.audioQueuePlayerDidEnqueueItems(tracks: items, at: enqueueAction)
    }
    
    func insert(tracks tracksToInsert: [AudioTrack], at index: Int) -> Int {
        guard let items = filter(tracksToInsert) else {
            return 0
        }
        nowPlayingQueueContext.insertItemsAtIndex(items, index: index)
        
        updateNowPlayingStateToIndex(nowPlayingQueueContext.indexOfNowPlayingItem, shouldLoadAfterUpdate: false)
		presentNotificationsIfNecessary()
        return items.count
    }
    
    func delete(at indicies: [Int]) {
        let nowPlayingItemRemoved = nowPlayingQueueContext.deleteItemsAtIndices(indicies)
        updateNowPlayingStateToIndex(nowPlayingQueueContext.indexOfNowPlayingItem, shouldLoadAfterUpdate: nowPlayingItemRemoved)
    }
    
    func move(from sourceIndex: Int, to destinationIndex: Int) {
        nowPlayingQueueContext.moveMediaItem(fromIndexPath: sourceIndex, toIndexPath: destinationIndex)
        updateNowPlayingStateToIndex(nowPlayingQueueContext.indexOfNowPlayingItem, shouldLoadAfterUpdate: false)
    }
    
    func clear(from direction: ClearDirection, at index: Int) {
        let nowPlayingItemRemoved = nowPlayingQueueContext.clearItems(towardsDirection: direction, atIndex: index)
        
        updateNowPlayingStateToIndex(nowPlayingQueueContext.indexOfNowPlayingItem, shouldLoadAfterUpdate: nowPlayingItemRemoved)
    }

    
    //MARK: Class Functions
    
    private func filter(_ tracks:[AudioTrack], presentUnplayableTracks:Bool = true) -> [AudioTrack]? {
        guard !tracks.isEmpty else { return nil }
        var unPlayableTrackNames = [String]()
        unPlayableTrackNames.reserveCapacity(tracks.count)
        var filteredTracks = [AudioTrack]()
        filteredTracks.reserveCapacity(tracks.count)
        
		
        for (i, track) in tracks.enumerated() {
            if track.assetURL == nil {
                unPlayableTrackNames.append("\(i + 1): \(track.trackTitle) - \(track.artist)")
            } else {
                filteredTracks.append(track)
            }
        }
        
        if !unPlayableTrackNames.isEmpty && presentUnplayableTracks {
            KyoozUtils.doInMainQueueAsync() {
                let message = "Filtered out tracks:\n\n" + unPlayableTrackNames.joined(separator: "\n")
                let ac = UIAlertController(title: "Enable Apple Music/iCloud Music Library in settings to play the following tracks", message: message, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                ContainerViewController.instance.present(ac, animated: true, completion: nil)
            }
        }
        
        guard !filteredTracks.isEmpty else { return nil }
        return filteredTracks
    }
    
    private func updateNowPlayingStateToIndex(_ newIndex:Int, shouldLoadAfterUpdate:Bool = true) {
        let nowPlayingQueue = self.nowPlayingQueue
        
        let reachedEndOfQueue = newIndex >= nowPlayingQueue.count
        if(reachedEndOfQueue) { pause() }

        indexOfNowPlayingItem = reachedEndOfQueue ? 0 : (newIndex < 0 ? 0 : newIndex)
        nowPlayingItem = nowPlayingQueue.isEmpty ? nil : nowPlayingQueue[indexOfNowPlayingItem]
        if(shouldLoadAfterUpdate && nowPlayingItem != nil) {
            loadMediaItem(nowPlayingItem!)
        }
    }
    

    private func loadMediaItem(_ mediaItem:AudioTrack) {
        func handleError() {
            if repeatMode == .one {
                repeatMode = .off
            }
            skipForwards()
        }
        
        do {
            guard let url:URL = mediaItem.assetURL else {
                throw NSError(domain: "Kyooz", code: 1, userInfo: [NSLocalizedDescriptionKey:"No URL found"])
            }
            
            try audioController.loadItem(url)
            
            if(shouldPlayAfterLoading) {
                play()
                nowPlayingInfoHelper.publishNowPlayingInfo(nowPlayingItem!)
            }
            publishNotification(for: .nowPlayingItemChanged)
        } catch let error as NSError {
            Logger.error("Could not load play track because of error [\(error.localizedDescription)] so skipping to next track")
            handleError()
        } catch {
            Logger.error("Unknown error occured when loading media item")
            handleError()
        }
    }
    
    func advanceToNextTrack(_ shouldLoadAfterUpdate:Bool) {
        updateNowPlayingStateToIndex(nextIndex, shouldLoadAfterUpdate: shouldLoadAfterUpdate)
    }
    
    
    //MARK: Remote Command Center Registration
    private func registerForRemoteCommands() {
        remoteCommandCenter.playCommand.addTarget { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            self.play()
            return MPRemoteCommandHandlerStatus.success
        }
        remoteCommandCenter.pauseCommand.addTarget { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            self.pause()
            return MPRemoteCommandHandlerStatus.success
        }
        remoteCommandCenter.togglePlayPauseCommand.addTarget { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            if(self.musicIsPlaying) {
                self.pause()
            } else {
                self.play()
            }
            return MPRemoteCommandHandlerStatus.success
        }
        remoteCommandCenter.previousTrackCommand.addTarget { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            self.skipBackwards(false)
            return MPRemoteCommandHandlerStatus.success
        }
        remoteCommandCenter.nextTrackCommand.addTarget { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            self.skipForwards()
            return MPRemoteCommandHandlerStatus.success
        }
    }
    
    private func unregisterForRemoteCommands() {
        remoteCommandCenter.playCommand.removeTarget(self)
        remoteCommandCenter.pauseCommand.removeTarget(self)
        remoteCommandCenter.togglePlayPauseCommand.removeTarget(self)
        remoteCommandCenter.previousTrackCommand.removeTarget(self)
        remoteCommandCenter.nextTrackCommand.removeTarget(self)
    }
    
    //MARK: Notification Center Registration
    private func registerForNotifications() {
//        let notificationCenter = NSNotificationCenter.defaultCenter()
//        let application = UIApplication.sharedApplication()
    }
    
    private func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: AudioControllerDelegate functions
    
    func audioPlayerDidFinishPlaying(_ player: AudioController, successfully flag: Bool) {
        if(flag) {
            KyoozUtils.doInMainQueue() {
                self.advanceToNextTrack(true)
            }
        } else {
            Logger.debug("audio player did not finish playing successfully")
        }
    }
    
    func audioPlayerDidRequestNextItemToBuffer(_ player:AudioController) -> URL? {
        let nextIndex = self.nextIndex
        let nextItem:AudioTrack? = (nextIndex >= nowPlayingQueue.count) ?  nil : nowPlayingQueue[nextIndex]
        if let url = nextItem?.assetURL {
            return url as URL
        }
        return nil
    }
    
    func audioPlayerDidAdvanceToNextItem(_ player:AudioController) {
        KyoozUtils.doInMainQueue() {
            self.advanceToNextTrack(false)
			self.publishNotification(for: .nowPlayingItemChanged)
			guard let nowPlayingItem = self.nowPlayingItem else {
				return
			}
            self.nowPlayingInfoHelper.publishNowPlayingInfo(nowPlayingItem)
        }
    }
}


