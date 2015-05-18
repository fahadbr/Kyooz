//
//  QueueBasedMusicPlayerController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/16/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer
import AVFoundation

typealias KVOContext=UInt8

class QueueBasedMusicPlayerImpl: NSObject,QueueBasedMusicPlayer,AVAudioPlayerDelegate {
    
    //MARK: STATIC INSTANCE
    static let instance:QueueBasedMusicPlayerImpl = QueueBasedMusicPlayerImpl()
    
    
    //MARK: Class Properties
    let nowPlayingInfoHelper = NowPlayingInfoHelper.instance
    let remoteCommandCenter = MPRemoteCommandCenter.sharedCommandCenter()
    
    var shouldPlayAfterLoading:Bool = false
    var avAudioPlayer:AVAudioPlayer?
    
    var nowPlayingQueue:[MPMediaItem] = [MPMediaItem]() {
        didSet {
            QueueBasedMusicPlayerNotificationPublisher.publishNotification(updateType: .QueueUpdate, sender: self)
        }
    }
    
    //MARK: Init/Deinit
    override init() {
        super.init()
        if let queue = TempDataDAO.instance.getNowPlayingQueueFromTempStorage() {
            nowPlayingQueue = queue
            dispatch_async(dispatch_get_main_queue(), { [unowned self]() -> Void in
                self.indexOfNowPlayingItem = 0
            })
        }
        if let playbackState = TempDataDAO.instance.getPlaybackStateFromTempStorage() {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.updateNowPlayingStateToIndex(playbackState.indexOfNowPlayingItem)
                self.currentPlaybackTime = playbackState.currentPlaybackTime
            })
        }
        registerForNotifications()
        registerForRemoteCommands()
    }
    
    deinit {
        unregisterForNotifications()
        unregisterForRemoteCommands()
    }
    
    //MARK: QueueBasedMusicPlayer - Properties
    var nowPlayingItem:MPMediaItem?
    
    var musicIsPlaying:Bool = false {
        didSet {
            shouldPlayAfterLoading = musicIsPlaying
            QueueBasedMusicPlayerNotificationPublisher.publishNotification(updateType: .PlaybackStateUpdate, sender: self)
            TempDataDAO.instance.persistCurrentPlaybackStateToTempStorage(indexOfNowPlayingItem, currentPlaybackTime: currentPlaybackTime)
            if nowPlayingItem != nil {
                nowPlayingInfoHelper.updateElapsedPlaybackTime(nowPlayingItem!, elapsedTime: currentPlaybackTime)
            }
        }
    }

    var currentPlaybackTime:Float {
        get {
            if let player = avAudioPlayer {
                return Float(player.currentTime)
            }
            return 0.0
        } set {
            if let player = avAudioPlayer {
                player.currentTime = Double(newValue)
                nowPlayingInfoHelper.updateElapsedPlaybackTime(nowPlayingItem!, elapsedTime:newValue)
                QueueBasedMusicPlayerNotificationPublisher.publishNotification(updateType: .PlaybackStateUpdate, sender: self)
            }
        }
    }
    var indexOfNowPlayingItem:Int = 0
    
    //MARK: QueueBasedMusicPlayer - Functions
    
    func play() {
        if let player = avAudioPlayer {
            player.play()
            musicIsPlaying = true
        }
    }
    
    func pause() {
        if let player = avAudioPlayer {
            player.pause()
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
    
    func getNowPlayingQueue() -> [MPMediaItem]? {
        return nowPlayingQueue
    }
    
    func playNowWithCollection(#mediaCollection:MPMediaItemCollection, itemToPlay:MPMediaItem) {
        nowPlayingQueue = mediaCollection.items as! [MPMediaItem]
        shouldPlayAfterLoading = true
        var i = 0
        for mediaItem in nowPlayingQueue {
            if(mediaItem.persistentID == itemToPlay.persistentID) {
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
    
    func enqueue(itemsToEnqueue:[MPMediaItem]) {
        nowPlayingQueue.extend(itemsToEnqueue)
    }
    
    func insertItemsAtIndex(itemsToInsert:[MPMediaItem], index:Int) {
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
    
    func moreBackgroundTimeIsNeeded() -> Bool {
        return false
    }
    
    func executePreBackgroundTasks() {
        
    }
    
    private func updateNowPlayingStateToIndex(newIndex:Int, shouldLoadAfterUpdate:Bool = true) {
        let reachedEndOfQueue = newIndex >= nowPlayingQueue.count
        if(reachedEndOfQueue) { pause() }

        indexOfNowPlayingItem = reachedEndOfQueue ? 0 : (newIndex < 0 ? 0 : newIndex)
        nowPlayingItem = nowPlayingQueue.isEmpty ? nil : nowPlayingQueue[indexOfNowPlayingItem]
        if(shouldLoadAfterUpdate && nowPlayingItem != nil) {
            loadMediaItem(nowPlayingItem!)
        }
    }
    
    //MARK: Class Functions
    private func loadMediaItem(mediaItem:MPMediaItem) {
        var url:NSURL = mediaItem.valueForProperty(MPMediaItemPropertyAssetURL) as! NSURL
        var error:NSError?
        avAudioPlayer = AVAudioPlayer(contentsOfURL: url, error: &error)
        if error != nil {
            Logger.debug("Error occured with loading audio for media item \(mediaItem.title): \(error!.description)")
            return
        }
        avAudioPlayer!.delegate = self
        avAudioPlayer!.prepareToPlay()
        if(shouldPlayAfterLoading) {
            play()
            nowPlayingInfoHelper.publishNowPlayingInfo(nowPlayingItem!)
        }
        QueueBasedMusicPlayerNotificationPublisher.publishNotification(updateType: .NowPlayingItemChanged, sender: self)
    }
    
    func scrobbleAndLoadNextTrack() {
        LastFmScrobbler.instance.scrobbleMediaItem(nowPlayingItem!)
        skipForwards()
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
    
    //MARK: AVAudioPlayerDelegate functions
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        if(flag) {
            scrobbleAndLoadNextTrack()
        } else {
            Logger.debug("audio player did not finish playing successfully")
        }
    }
}


