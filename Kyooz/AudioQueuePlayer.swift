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
    
    func skipBackwards(forcePreviousTrack:Bool)
    
    func skipForwards()
    
    func playNow(withTracks tracks:[AudioTrack], startingAtIndex index:Int, shouldShuffleIfOff:Bool)
    
    func playTrack(at index:Int)
    
    func enqueue(tracks tracksToEnqueue:[AudioTrack], at enqueueAction:EnqueueAction)
    
    //returns the number of items inserted
    func insert(tracks tracksToInsert:[AudioTrack], at index:Int) -> Int
    
    func delete(at indicies:[Int])
    
    func move(from sourceIndex:Int, to destinationIndex:Int)
    
    func clear(from direction:ClearDirection, at index:Int)
    
    
}

extension AudioQueuePlayer {
    func publishNotification(for updateType:AudioQueuePlayerUpdate) {
        KyoozUtils.doInMainQueueAsync() {
            let notification = NSNotification(name: updateType.rawValue, object: self)
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
    
    func audioQueuePlayerDidEnqueueItems(tracks tracksToEnqueue:[AudioTrack], at enqueueAction:EnqueueAction)
    
}

enum AudioQueuePlayerUpdate : String, EnumNameDescriptable {
    case queueUpdate
    case systematicQueueUpdate
    case playbackStateUpdate
    case nowPlayingItemChanged
}

enum ClearDirection : Int, EnumNameDescriptable {
    case above
    case below
    case bothDirections
}

enum EnqueueAction : Int, EnumNameDescriptable {
    case next
    case last
    case random
}

