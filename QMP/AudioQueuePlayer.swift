//
//  AudioQueuePlayer.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

protocol AudioQueuePlayer:class {
    
    var playbackStateSnapshot:PlaybackStateSnapshot { get }
    
    var nowPlayingItem:AudioTrack? { get }
    var musicIsPlaying:Bool { get }
    var currentPlaybackTime:Float { get set }
    var indexOfNowPlayingItem:Int { get }
    var nowPlayingQueue:[AudioTrack] { get }
    var shuffleActive:Bool { get set }
    var repeatMode:RepeatState { get set }
    
    func play()
    
    func pause()
    
    func skipBackwards()
    
    func skipForwards()
    
    func playNow(withTracks tracks:[AudioTrack], startingAtIndex index:Int, completionBlock:(()->())?)
    
    func playItemWithIndexInCurrentQueue(index index:Int)
    
    func enqueue(items itemsToEnqueue:[AudioTrack], atPosition position:EnqueuePosition)
    
    func insertItemsAtIndex(itemsToInsert:[AudioTrack], index:Int)
    
    func deleteItemsAtIndices(indicies:[Int])
    
    func moveMediaItem(fromIndexPath fromIndexPath:Int, toIndexPath:Int)
    
    func clearItems(towardsDirection direction:ClearDirection, atIndex index:Int)
    
    
}

extension AudioQueuePlayer {
    func publishNotification(updateType updateType:AudioQueuePlayerUpdate, sender:AudioQueuePlayer) {
//        if let item = sender.nowPlayingItem { NowPlayingInfoHelper.instance.publishNowPlayingInfo(item) }
        KyoozUtils.doInMainQueueAsync() {
            let notification = NSNotification(name: updateType.rawValue, object: sender)
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
    }
}

enum AudioQueuePlayerUpdate : String {
    case QueueUpdate = "AudioQueuePlayerQueueUpdate"
    case PlaybackStateUpdate = "AudioQueuePlayerPlaybackStatusUpdate"
    case NowPlayingItemChanged = "AudioQueuePlayerNowPlayingItemChanged"
}

enum ClearDirection : Int {
    case Above
    case Below
    case All
}

enum EnqueuePosition : Int {
    case Next
    case Last
    case Random
}

