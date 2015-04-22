//
//  QueueBasedMusicPlayer.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

@objc protocol QueueBasedMusicPlayer {
    
    var nowPlayingItem:MPMediaItem? { get }
    var musicIsPlaying:Bool { get }
    var currentPlaybackTime:NSTimeInterval { get }
    
    func play()
    
    func pause()
    
    func getNowPlayingQueue() -> [MPMediaItem]?
    
    func playNowWithCollection(#mediaCollection:MPMediaItemCollection, itemToPlay:MPMediaItem)
    
    func playItemWithIndexInCurrentQueue(#index:Int)
    
    func enqueue(itemsToEnque:[MPMediaItem])
    
    func deleteItemAtIndexFromQueue(index:Int)
    
    func rearrangeMediaItems(fromIndexPath:Int, toIndexPath:Int)
    
    func clearUpcomingItems()
    
    optional func moreBackgroundTimeIsNeeded() -> Bool
    
    optional func executePreBackgroundTasks()
    
}