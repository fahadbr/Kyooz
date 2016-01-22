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
    
    var type:AudioQueuePlayerType { get }
    var playbackStateSnapshot:PlaybackStateSnapshot { get set }
    
    var nowPlayingItem:AudioTrack? { get }
    var musicIsPlaying:Bool { get }
    var currentPlaybackTime:Float { get set }
    var indexOfNowPlayingItem:Int { get }
    var nowPlayingQueue:[AudioTrack] { get }
    var shuffleActive:Bool { get set }
    var repeatMode:RepeatState { get set }
    
    var delegate:AudioQueuePlayerDelegate? { get set }
    
    func play()
    
    func pause()
    
    func skipBackwards()
    
    func skipForwards()
    
    func playNow(withTracks tracks:[AudioTrack], startingAtIndex index:Int, shouldShuffleIfOff:Bool)
    
    func playItemWithIndexInCurrentQueue(index index:Int)
    
    func enqueue(items itemsToEnqueue:[AudioTrack], atPosition position:EnqueuePosition)
    
    //returns the number of items inserted
    func insertItemsAtIndex(itemsToInsert:[AudioTrack], index:Int) -> Int
    
    func deleteItemsAtIndices(indicies:[Int])
    
    func moveMediaItem(fromIndexPath fromIndexPath:Int, toIndexPath:Int)
    
    func clearItems(towardsDirection direction:ClearDirection, atIndex index:Int)
    
    
}

extension AudioQueuePlayer {
    func publishNotification(updateType updateType:AudioQueuePlayerUpdate, sender:AudioQueuePlayer) {
        KyoozUtils.doInMainQueueAsync() {
            let notification = NSNotification(name: updateType.rawValue, object: sender)
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
    }
    
    func presentNotificationsIfNecessary() {
        if repeatMode == .One {
            let ac = UIAlertController(title: "Turn off Repeat One Mode?", message: "The tracks you just queued won't play until Repeat One Mode is turned off", preferredStyle: .Alert)
            let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: {_ -> Void in
                self.repeatMode = .Off
            })
            ac.addAction(yesAction)
            ac.preferredAction = yesAction
            ac.addAction(UIAlertAction(title: "No", style: .Cancel, handler: nil))
            ContainerViewController.instance.presentViewController(ac, animated: true, completion: nil)
            return
        }
    }
}

protocol AudioQueuePlayerDelegate {
    
	func audioQueuePlayerDidChangeContext(audioQueuePlayer: AudioQueuePlayer, previousSnapshot:PlaybackStateSnapshot)
    
    func audioQueuePlayerDidEnqueueItems(items:[AudioTrack], position:EnqueuePosition)
    
}

enum AudioQueuePlayerUpdate : String {
    case QueueUpdate = "AudioQueuePlayerQueueUpdate"
    case SystematicQueueUpdate = "AudioQueuePlayerSystematicQueueUpdate"
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

