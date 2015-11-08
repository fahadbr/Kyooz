//
//  PlaybackStateManager.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/8/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

class PlaybackStateManager: NSObject {
    
    class var instance : PlaybackStateManager {
        struct Static {
            static let instance:PlaybackStateManager = PlaybackStateManager()
        }
        return Static.instance
    }
    
    static let PlaybackStateCorrectedNotification = "PlaybackStateCorrectedNotification"
   
    private let musicPlayer = ApplicationDefaults.defaultMusicPlayerController
    private let audioSession = AVAudioSession.sharedInstance()
    private let timeDelayInNanoSeconds = Int64((1.0/4.0) * Double(NSEC_PER_SEC))
    private (set) var musicPlaybackState:MPMusicPlaybackState
    
    
    override init(){
        self.musicPlaybackState = musicPlayer.playbackState
        super.init()
        self.registerForNotifications()
    }
   
    
    func musicIsPlaying() -> Bool {
        return musicPlaybackState == MPMusicPlaybackState.Playing
    }
    
    func otherMusicIsPlaying() -> Bool {
        return !musicIsPlaying() && audioSession.secondaryAudioShouldBeSilencedHint
    }

    func correctPlaybackState() {
        let dispatchTime1 = dispatch_time(DISPATCH_TIME_NOW, self.timeDelayInNanoSeconds)
        dispatch_after(dispatchTime1, dispatch_get_main_queue(), { [unowned self]() -> Void in
            let oldPlaybackTime = self.musicPlayer.currentPlaybackTime
            Logger.debug("oldPlaybackTime: \(oldPlaybackTime)")
            
            let dispatchTime2 = dispatch_time(DISPATCH_TIME_NOW, self.timeDelayInNanoSeconds)
            dispatch_after(dispatchTime2, dispatch_get_main_queue(), { [unowned self] ()  in
                self.checkAgainstPlaybackTime(oldPlaybackTime)
            })
        })
    }
    
    private func checkAgainstPlaybackTime(playbackTime : NSTimeInterval) {
        let newPlaybackTime = self.musicPlayer.currentPlaybackTime
        var playbackStateCorrected:Bool = false
        Logger.debug("newPlaybackTime: \(newPlaybackTime)")

        if(newPlaybackTime.isNaN && playbackTime.isNaN) {
            if(self.musicPlaybackState != MPMusicPlaybackState.Stopped) {
                self.musicPlaybackState = MPMusicPlaybackState.Stopped
                playbackStateCorrected = true
            }
        } else {
            if(newPlaybackTime != playbackTime && self.musicPlaybackState != MPMusicPlaybackState.Playing) {
                self.musicPlaybackState = MPMusicPlaybackState.Playing
                playbackStateCorrected = true
            } else if (newPlaybackTime == playbackTime && self.musicPlaybackState == MPMusicPlaybackState.Playing) {
                self.musicPlaybackState = MPMusicPlaybackState.Paused
                playbackStateCorrected = true
            }
        }
        
        if(playbackStateCorrected) {
            Logger.debug("Playback State Corrected to: \(self.musicPlaybackState.rawValue.description)")
            dispatch_async(dispatch_get_main_queue()) {
                let notification = NSNotification(name: PlaybackStateManager.PlaybackStateCorrectedNotification, object: self)
                NSNotificationCenter.defaultCenter().postNotification(notification)
            }
        }

    }
    

    
    func handlePlaybackStateChanged(notification:NSNotification){
        if(notification.userInfo != nil) {
            let object: AnyObject? = notification.userInfo!["MPMusicPlayerControllerPlaybackStateKey"]
            if(object != nil) {
                let stateRawValue = object! as! Int
                let stateToSet = MPMusicPlaybackState(rawValue: stateRawValue)
                if(stateToSet != nil) {
                    self.musicPlaybackState = stateToSet!
                    Logger.debug("CurrentPlaybackState: " + self.musicPlaybackState.rawValue.description)
                }
            }
        }
    }
    
    private func registerForNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handlePlaybackStateChanged:",
            name:MPMusicPlayerControllerPlaybackStateDidChangeNotification,
            object: musicPlayer)
        musicPlayer.beginGeneratingPlaybackNotifications()
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMusicPlayerControllerPlaybackStateDidChangeNotification, object: musicPlayer)
        musicPlayer.endGeneratingPlaybackNotifications()
    }

    
}
