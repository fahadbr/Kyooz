//
//  QueueBasedMusicPlayer.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

protocol QueueBasedMusicPlayer:class {
    
    var nowPlayingItem:MPMediaItem? { get }
    var musicIsPlaying:Bool { get }
    var currentPlaybackTime:Float { get set }
    var indexOfNowPlayingItem:Int { get }
    
    func play()
    
    func pause()
    
    func skipBackwards()
    
    func skipForwards()
    
    func getNowPlayingQueue() -> [MPMediaItem]?
    
    func playNowWithCollection(#mediaCollection:MPMediaItemCollection, itemToPlay:MPMediaItem)
    
    func playItemWithIndexInCurrentQueue(#index:Int)
    
    func enqueue(itemsToEnque:[MPMediaItem])
    
    func deleteItemsAtIndices(indicies:[Int])
    
    func moveMediaItem(#fromIndexPath:Int, toIndexPath:Int)
    
    func clearUpcomingItems(#fromIndex:Int)
    
    func moreBackgroundTimeIsNeeded() -> Bool
    
    func executePreBackgroundTasks()
    
}

enum QueueBasedMusicPlayerUpdate : String {
    case QueueUpdate = "QueueBasedMusicPlayerQueueUpdate"
    case PlaybackStateUpdate = "QueueBasedMusicPlayerPlaybackStatusUpdate"
    case NowPlayingItemChanged = "QueueBasedMusicPlayerNowPlayingItemChanged"
}

struct QueueBasedMusicPlayerNotificationPublisher {
    
    static func publishNotification(#updateType:QueueBasedMusicPlayerUpdate, sender:QueueBasedMusicPlayer) {
        let notificationPublication = {() -> Void in
            let notification = NSNotification(name: updateType.rawValue, object: sender)
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
        
        dispatch_async(dispatch_get_main_queue(), notificationPublication)
    }
}

