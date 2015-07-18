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
    
    var nowPlayingItem:AudioTrack? { get }
    var musicIsPlaying:Bool { get }
    var currentPlaybackTime:Float { get set }
    var indexOfNowPlayingItem:Int { get }
    var nowPlayingQueue:[AudioTrack] { get }
    
    func play()
    
    func pause()
    
    func skipBackwards()
    
    func skipForwards()
    
    func playNowWithCollection(#mediaCollection:MPMediaItemCollection, itemToPlay:AudioTrack)
    
    func playItemWithIndexInCurrentQueue(#index:Int)
    
    func enqueue(itemsToEnque:[AudioTrack])
    
    func insertItemsAtIndex(itemsToInsert:[AudioTrack], index:Int)
    
    func deleteItemsAtIndices(indicies:[Int])
    
    func moveMediaItem(#fromIndexPath:Int, toIndexPath:Int)
    
    func clearUpcomingItems(#fromIndex:Int)
}

enum AudioQueuePlayerUpdate : String {
    case QueueUpdate = "AudioQueuePlayerQueueUpdate"
    case PlaybackStateUpdate = "AudioQueuePlayerPlaybackStatusUpdate"
    case NowPlayingItemChanged = "AudioQueuePlayerNowPlayingItemChanged"
}

struct AudioQueuePlayerNotificationPublisher {
    
    static func publishNotification(#updateType:AudioQueuePlayerUpdate, sender:AudioQueuePlayer) {
        let notificationPublication = {() -> Void in
            let notification = NSNotification(name: updateType.rawValue, object: sender)
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
        
        dispatch_async(dispatch_get_main_queue(), notificationPublication)
    }
}

