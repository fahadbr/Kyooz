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
    var currentPlaybackTime:NSTimeInterval { get }
    var indexOfNowPlayingItem:Int { get }
    
    func play()
    
    func pause()
    
    func getNowPlayingQueue() -> [MPMediaItem]?
    
    func playNowWithCollection(#mediaCollection:MPMediaItemCollection, itemToPlay:MPMediaItem)
    
    func playItemWithIndexInCurrentQueue(#index:Int)
    
    func enqueue(itemsToEnque:[MPMediaItem])
    
    func deleteItemAtIndexFromQueue(index:Int)
    
    func rearrangeMediaItems(fromIndexPath:Int, toIndexPath:Int)
    
    func clearUpcomingItems(#fromIndex:Int)
    
    func moreBackgroundTimeIsNeeded() -> Bool
    
    func executePreBackgroundTasks()
    
}

enum QueueBasedMusicPlayerNoficiation : String {
    case QueueUpdate = "QueueBasedMusicPlayerQueueUpdate"
    case PlaybackStateUpdate = "QueueBasedMusicPlayerPlaybackStatusUpdate"
    case NowPlayingItemChanged = "QueueBasedMusicPlayerNowPlayingItemChanged"
}

