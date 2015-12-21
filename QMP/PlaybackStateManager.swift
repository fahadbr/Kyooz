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
    private let timeDelayInSeconds:Double = 1.0/4.0
    private let stateDescriptions = ["Stopped", "Playing", "Paused", "Interrupted", "SeekingForward", "SeekingBackward"]
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
        dispatch_after(KyoozUtils.getDispatchTimeForSeconds(timeDelayInSeconds), dispatch_get_main_queue(), { [unowned self]() -> Void in
            let oldPlaybackTime = self.musicPlayer.currentPlaybackTime
            Logger.debug("old time = \(oldPlaybackTime)")
            dispatch_after(KyoozUtils.getDispatchTimeForSeconds(self.timeDelayInSeconds), dispatch_get_main_queue(), { [unowned self] ()  in
                self.checkAgainstPlaybackTime(oldPlaybackTime)
            })
        })
    }
    
    private func checkAgainstPlaybackTime(playbackTime : NSTimeInterval) {
        let newPlaybackTime = self.musicPlayer.currentPlaybackTime
        Logger.debug("new time = \(newPlaybackTime)")
        var playbackStateCorrected:Bool = false

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
            var description:String?
            if musicPlaybackState.rawValue < stateDescriptions.count {
                description = stateDescriptions[musicPlaybackState.rawValue]
            }
            Logger.debug("Playback State Corrected to: \(description ?? "unknown")")
            KyoozUtils.doInMainQueueAsync() {
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
//                    Logger.debug("CurrentPlaybackState: " + self.musicPlaybackState.rawValue.description)
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
