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

class AudioQueuePlayerImpl: NSObject,AudioQueuePlayer,AudioControllerDelegate {
    
    //MARK: STATIC INSTANCE
    static let instance:AudioQueuePlayerImpl = AudioQueuePlayerImpl()
    
    
    //MARK: Class Properties
    let nowPlayingInfoHelper = NowPlayingInfoHelper.instance
    let remoteCommandCenter = MPRemoteCommandCenter.sharedCommandCenter()
    
    var shouldPlayAfterLoading:Bool = false
    var audioController:AudioController = ApplicationDefaults.audioController
    var lastFmScrobbler = LastFmScrobbler.instance
    
    var nowPlayingQueue:[AudioTrack] = [AudioTrack]() {
        didSet {
            AudioQueuePlayerNotificationPublisher.publishNotification(updateType: .QueueUpdate, sender: self)
        }
    }
    
    //MARK: Init/Deinit
    override init() {
        super.init()
        audioController.delegate = self
        if let queue = TempDataDAO.instance.getNowPlayingQueueFromTempStorage() {
            nowPlayingQueue = queue
            if let playbackState = TempDataDAO.instance.getPlaybackStateFromTempStorage() {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.updateNowPlayingStateToIndex(playbackState.indexOfNowPlayingItem)
                    self.currentPlaybackTime = playbackState.currentPlaybackTime.isNormal ? playbackState.currentPlaybackTime : 0
                })
            }
        }

        registerForNotifications()
        registerForRemoteCommands()
    }
    
    deinit {
        unregisterForNotifications()
        unregisterForRemoteCommands()
    }
    
    //MARK: AudioQueuePlayer - Properties
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
            AudioQueuePlayerNotificationPublisher.publishNotification(updateType: .PlaybackStateUpdate, sender: self)
            TempDataDAO.instance.persistCurrentPlaybackStateToTempStorage(indexOfNowPlayingItem, currentPlaybackTime: currentPlaybackTime)
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
                audioController.currentPlaybackTime = Double(newValue)
                nowPlayingInfoHelper.updateElapsedPlaybackTime(nowPlayingItem!, elapsedTime:newValue)
                AudioQueuePlayerNotificationPublisher.publishNotification(updateType: .PlaybackStateUpdate, sender: self)
            }
        }
    }
    var indexOfNowPlayingItem:Int = 0
    
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
        updateNowPlayingStateToIndex(indexOfNowPlayingItem + 1)
    }
    
    func skipBackwards() {
        if(currentPlaybackTime < 2.0) {
            updateNowPlayingStateToIndex(indexOfNowPlayingItem - 1)
        } else {
            currentPlaybackTime = 0.0
        }
    }
    
    func playNowWithCollection(#mediaCollection:MPMediaItemCollection, itemToPlay:AudioTrack) {
        nowPlayingQueue = mediaCollection.items as! [AudioTrack]
        shouldPlayAfterLoading = true
        var i = 0
        for mediaItem in nowPlayingQueue {
            if(mediaItem.id == itemToPlay.id) {
                updateNowPlayingStateToIndex(i)
            }
            i++
        }
    }
    
    func playItemWithIndexInCurrentQueue(#index:Int) {
        if(index == indexOfNowPlayingItem) {
            return
        }
        shouldPlayAfterLoading = true
        updateNowPlayingStateToIndex(index)
    }
    
    func enqueue(itemsToEnqueue:[AudioTrack]) {
        nowPlayingQueue.extend(itemsToEnqueue)
    }
    
    func insertItemsAtIndex(itemsToInsert:[AudioTrack], index:Int) {
        nowPlayingQueue.insertAtIndex(itemsToInsert, index: index, placeHolderItem: MPMediaItem())
        
        if(index <= indexOfNowPlayingItem) {
            updateNowPlayingStateToIndex(indexOfNowPlayingItem + itemsToInsert.count, shouldLoadAfterUpdate: false)
        }
    }
    
    func deleteItemsAtIndices(indiciesToRemove:[Int]) {
        var indicies = indiciesToRemove
        if(indicies.count > 1) {
            //if removing more than 1 element, sort the array otherwise we will run into index out of bounds issues
            indicies.sort { $0 > $1 }
        }
        var nowPlayingItemRemoved = false
        for index in indicies {
            nowPlayingQueue.removeAtIndex(index)
            if(index < indexOfNowPlayingItem) {
                updateNowPlayingStateToIndex(indexOfNowPlayingItem - 1, shouldLoadAfterUpdate: false)
            } else if (index == indexOfNowPlayingItem) {
                nowPlayingItemRemoved = true
            }
        }
        
        if(nowPlayingItemRemoved) {
            updateNowPlayingStateToIndex(0)
        }
    }
    
    func moveMediaItem(#fromIndexPath:Int, toIndexPath:Int) {
        let tempMediaItem = nowPlayingQueue[fromIndexPath]
        nowPlayingQueue.removeAtIndex(fromIndexPath)
        nowPlayingQueue.insert(tempMediaItem, atIndex: toIndexPath)
        
        if(fromIndexPath == indexOfNowPlayingItem) {
            updateNowPlayingStateToIndex(toIndexPath, shouldLoadAfterUpdate: false)
        } else if(fromIndexPath < indexOfNowPlayingItem && indexOfNowPlayingItem <= toIndexPath) {
            updateNowPlayingStateToIndex(indexOfNowPlayingItem - 1, shouldLoadAfterUpdate: false)
        } else if(toIndexPath <= indexOfNowPlayingItem && indexOfNowPlayingItem < fromIndexPath) {
            updateNowPlayingStateToIndex(indexOfNowPlayingItem + 1, shouldLoadAfterUpdate: false)
        }
    }
    
    func clearUpcomingItems(#fromIndex:Int) {
        nowPlayingQueue.removeRange((fromIndex + 1)..<nowPlayingQueue.count)
        if(fromIndex < indexOfNowPlayingItem) {
            updateNowPlayingStateToIndex(0, shouldLoadAfterUpdate: true)
        }
    }

    
    //MARK: Class Functions
    
    private func updateNowPlayingStateToIndex(newIndex:Int, shouldLoadAfterUpdate:Bool = true) {
        let reachedEndOfQueue = newIndex >= nowPlayingQueue.count
        if(reachedEndOfQueue) { pause() }

        indexOfNowPlayingItem = reachedEndOfQueue ? 0 : (newIndex < 0 ? 0 : newIndex)
        nowPlayingItem = nowPlayingQueue.isEmpty ? nil : nowPlayingQueue[indexOfNowPlayingItem]
        if(shouldLoadAfterUpdate && nowPlayingItem != nil) {
            loadMediaItem(nowPlayingItem!)
        }
    }
    

    private func loadMediaItem(mediaItem:AudioTrack) {
        var url:NSURL = mediaItem.assetURL
        let audioPlayerDidLoadItem = audioController.loadItem(url)
        if(!audioPlayerDidLoadItem) { return }
        
        if(shouldPlayAfterLoading) {
            play()
            nowPlayingInfoHelper.publishNowPlayingInfo(nowPlayingItem!)
        }
        AudioQueuePlayerNotificationPublisher.publishNotification(updateType: .NowPlayingItemChanged, sender: self)
    }
    
    func advanceToNextTrack(shouldLoadAfterUpdate:Bool) {
        updateNowPlayingStateToIndex(indexOfNowPlayingItem + 1, shouldLoadAfterUpdate: shouldLoadAfterUpdate)
    }
    
    
    //MARK: Remote Command Center Registration
    private func registerForRemoteCommands() {
        remoteCommandCenter.playCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            self.play()
            return MPRemoteCommandHandlerStatus.Success
        }
        remoteCommandCenter.pauseCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            self.pause()
            return MPRemoteCommandHandlerStatus.Success
        }
        remoteCommandCenter.togglePlayPauseCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            if(self.musicIsPlaying) {
                self.pause()
            } else {
                self.play()
            }
            return MPRemoteCommandHandlerStatus.Success
        }
        remoteCommandCenter.previousTrackCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            self.skipBackwards()
            return MPRemoteCommandHandlerStatus.Success
        }
        remoteCommandCenter.nextTrackCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
            self.skipForwards()
            return MPRemoteCommandHandlerStatus.Success
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
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let application = UIApplication.sharedApplication()
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //MARK: AudioControllerDelegate functions
    
    func audioPlayerDidFinishPlaying(player: AudioController, successfully flag: Bool) {
        if(flag) {
            advanceToNextTrack(true)
        } else {
            Logger.debug("audio player did not finish playing successfully")
        }
    }
    
    func audioPlayerDidRequestNextItemToBuffer(player:AudioController) -> NSURL? {
        let nextIndex = indexOfNowPlayingItem + 1
        let nextItem:AudioTrack? = (nextIndex >= nowPlayingQueue.count) ?  nil : nowPlayingQueue[nextIndex]
        if let url = nextItem?.assetURL {
            return url
        }
        return nil
    }
    
    func audioPlayerDidAdvanceToNextItem(player:AudioController) {
        advanceToNextTrack(false)
        
        nowPlayingInfoHelper.publishNowPlayingInfo(nowPlayingItem!)
        AudioQueuePlayerNotificationPublisher.publishNotification(updateType: .NowPlayingItemChanged, sender: self)
    }
}


