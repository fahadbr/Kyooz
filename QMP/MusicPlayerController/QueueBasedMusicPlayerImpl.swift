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

class QueueBasedMusicPlayerImpl: NSObject,QueueBasedMusicPlayer {
    
    let nowPlayingInfoHelper = NowPlayingInfoHelper.instance
    let remoteCommandCenter = MPRemoteCommandCenter.sharedCommandCenter()
    
    typealias KVOContext=UInt8
    var observationContext = KVOContext()
    var avPlayer:AVPlayer?
    
    var avQueuePlayer = AVQueuePlayer()
    var avPlayerItem:AVPlayerItem?
    
    private(set) var nowPlayingItem:MPMediaItem?
    private(set) var musicIsPlaying:Bool = false
    private(set) var currentPlaybackTime:NSTimeInterval = 0.0
    private (set) var indexOfNowPlayingItem:Int = 0
    
    class var instance : QueueBasedMusicPlayerImpl {
        struct Static {
            static let instance:QueueBasedMusicPlayerImpl = QueueBasedMusicPlayerImpl()
        }
        return Static.instance
    }
    
    override init() {
        super.init()
        registerForRemoteCommands()
    }
    
    deinit {
        unregisterForRemoteCommands()
    }
    
    func play() {
        if(avPlayer != nil) {
            avPlayer!.play()
            println("music is playing")
            musicIsPlaying = true
        }
    }
    
    func pause() {
        if(avPlayer != nil) {
            avPlayer!.pause()
            println("music is paused")
            musicIsPlaying = false
        }
        
    }
    
    func getNowPlayingQueue() -> [MPMediaItem]? {
        if(nowPlayingItem != nil) {
            return [nowPlayingItem!]
        }
        return nil
    }
    
    func playNowWithCollection(#mediaCollection:MPMediaItemCollection, itemToPlay:MPMediaItem) {
        playItem(itemToPlay)
    }
    
    func playItemWithIndexInCurrentQueue(#index:Int) {
        
    }
    
    func enqueue(itemsToEnque:[MPMediaItem]) {
        
    }
    
    func deleteItemAtIndexFromQueue(index:Int) {
        
    }
    
    func rearrangeMediaItems(fromIndexPath:Int, toIndexPath:Int) {
        
    }
    
    func clearUpcomingItems(#fromIndex:Int) {
        
    }
    
    func moreBackgroundTimeIsNeeded() -> Bool {
        return false
    }
    
    func executePreBackgroundTasks() {
        
    }
    
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
    }
    private func unregisterForRemoteCommands() {
        remoteCommandCenter.playCommand.removeTarget(self)
        remoteCommandCenter.pauseCommand.removeTarget(self)
        remoteCommandCenter.togglePlayPauseCommand.removeTarget(self)
    }
    
    private func playItem(mediaItem:MPMediaItem) {
        nowPlayingItem = mediaItem
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
        self.nowPlayingInfoHelper.publishNowPlayingInfo(nowPlayingItem!)
    }
    
    
    private func getAVURLAsset(#fromMediaItem:MPMediaItem) -> AVURLAsset{
        var url:NSURL = fromMediaItem.valueForProperty(MPMediaItemPropertyAssetURL) as! NSURL
        return AVURLAsset(URL: url, options: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        switch(keyPath) {
        case("status"):
            println("status has changed to \(change)")
            if(avPlayer?.currentItem?.status != nil && avPlayer?.currentItem?.status == AVPlayerItemStatus.ReadyToPlay) {
                play()
                avPlayer?.currentItem?.removeObserver(self, forKeyPath: "status")
                println("status is ready to play")
            }
        default:
            println("non observed property has changed")
        }
    }
}
