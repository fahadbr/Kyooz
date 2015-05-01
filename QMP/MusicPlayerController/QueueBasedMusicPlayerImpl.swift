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

class QueueBasedMusicPlayerImpl: NSObject,QueueBasedMusicPlayer {
    
    //MARK: STATIC INSTANCE
    static let instance:QueueBasedMusicPlayerImpl = QueueBasedMusicPlayerImpl()
    
    
    //MARK: Class Properties
    let nowPlayingInfoHelper = NowPlayingInfoHelper.instance
    let remoteCommandCenter = MPRemoteCommandCenter.sharedCommandCenter()
    
    var observationContext = KVOContext()
    var avPlayer:AVPlayer?
    var timeObserver:AnyObject?
    var avPlayerItem:AVPlayerItem?
    var shouldPlayAfterLoading:Bool = false
    var restoredPlaybackTime:Float?
    
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
                self.restoredPlaybackTime = playbackState.currentPlaybackTime
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
            if(musicIsPlaying) {
                addTimeObserver()
            } else {
                removeTimeObserver()
            }
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
            if let player = avPlayer {
                return player.currentTime().seconds
            }
            return 0.0
        } set {
            avPlayer?.seekToTime(CMTime.fromSeconds(newValue), completionHandler: { (finished:Bool) -> Void in
                if(finished) {
                    self.nowPlayingInfoHelper.updateElapsedPlaybackTime(self.nowPlayingItem!, elapsedTime:newValue)
                }
            })
            QueueBasedMusicPlayerNotificationPublisher.publishNotification(updateType: .PlaybackStateUpdate, sender: self)
        }
    }
    var indexOfNowPlayingItem:Int = 0
    
    //MARK: QueueBasedMusicPlayer - Functions
    
    func play() {
        if(avPlayer != nil) {
            avPlayer!.play()
            musicIsPlaying = true
        }
    }
    
    func pause() {
        if(avPlayer != nil) {
            avPlayer!.pause()
            musicIsPlaying = false
        }
    }
    
    func skipForwards() {
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
        shouldPlayAfterLoading = true
        updateNowPlayingStateToIndex(index)
    }
    
    func enqueue(itemsToEnqueue:[MPMediaItem]) {
        nowPlayingQueue.extend(itemsToEnqueue)
    }
    
    func deleteItemAtIndexFromQueue(index:Int) {
        nowPlayingQueue.removeAtIndex(index)
        if(index < indexOfNowPlayingItem) {
            updateNowPlayingStateToIndex(indexOfNowPlayingItem - 1, shouldLoadAfterUpdate: false)
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
        nowPlayingQueue.removeRange(Range<Int>(start: fromIndex + 1, end: nowPlayingQueue.count))
    }
    
    func moreBackgroundTimeIsNeeded() -> Bool {
        return false
    }
    
    func executePreBackgroundTasks() {
        
    }
    
    private func updateNowPlayingStateToIndex(newIndex:Int, shouldLoadAfterUpdate:Bool = true) {
        let reachedEndOfQueue = newIndex >= nowPlayingQueue.count
        if(reachedEndOfQueue) { pause() }

        indexOfNowPlayingItem = reachedEndOfQueue ? 0 : newIndex
        nowPlayingItem = nowPlayingQueue[indexOfNowPlayingItem]
        if(shouldLoadAfterUpdate && nowPlayingItem != nil) {
            loadMediaItem(nowPlayingItem!)
        }
    }
    
    //MARK: Class Functions
    private func loadMediaItem(mediaItem:MPMediaItem) {
        removeTimeObserver()
        var url:NSURL = mediaItem.valueForProperty(MPMediaItemPropertyAssetURL) as! NSURL
        var songAsset = AVURLAsset(URL: url, options: nil)
        let tracksKey = "tracks"
        var error:NSErrorPointer = NSErrorPointer()
        songAsset.loadValuesAsynchronouslyForKeys([tracksKey], completionHandler: { [unowned self]() in
            let status = songAsset.statusOfValueForKey(tracksKey, error: error)
            if(status == AVKeyValueStatus.Loaded) {
                self.avPlayerItem = AVPlayerItem(asset: songAsset)
                self.avPlayerItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: &self.observationContext)
                self.avPlayer = AVPlayer(playerItem: self.avPlayerItem!)
            }
        })
    }
    
    func addTimeObserver() {
        if(timeObserver == nil) {
            let playbackDuration = NSValue(CMTime: CMTime.fromSeconds(Float(nowPlayingItem!.playbackDuration)))
            timeObserver = avPlayer!.addBoundaryTimeObserverForTimes([playbackDuration],
                queue: dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), usingBlock: self.skipForwards)
            println("adding time observer \(timeObserver)")
        } else {
            fatalError("tried to add time observer before previous one was removed")
        }
    }
    
    func removeTimeObserver() {
        if(timeObserver != nil) {
            println("removing time observer \(timeObserver)")
            avPlayer?.removeTimeObserver(timeObserver!)
            timeObserver = nil
        }
    }
    

    //MARK: KVO function
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        switch(keyPath) {
        case("status"):
            println("status has changed to \(change)")
            if(avPlayer?.currentItem?.status != nil && avPlayer?.currentItem?.status == AVPlayerItemStatus.ReadyToPlay) {
                if(shouldPlayAfterLoading) {
                    play()
                }
                avPlayer?.currentItem?.removeObserver(self, forKeyPath: "status")
                println("Media item \(nowPlayingItem!.title) is ready to play")
                nowPlayingInfoHelper.publishNowPlayingInfo(nowPlayingItem!)
                QueueBasedMusicPlayerNotificationPublisher.publishNotification(updateType: .NowPlayingItemChanged, sender: self)
                if let playbackTime = restoredPlaybackTime {
                    currentPlaybackTime = playbackTime
                    restoredPlaybackTime = nil
                }
            }
        default:
            println("non observed property has changed")
        }
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
}

extension CMTime {
    
    static func fromSeconds(seconds:Float) -> CMTime {
        return CMTimeMakeWithSeconds(Double(seconds), Int32(1))
    }
    
    var seconds:Float {
        if(value == 0) {
            return 0.0
        }
        return Float(value)/Float(timescale)
    }
}
