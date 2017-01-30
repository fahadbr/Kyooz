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

final class PlaybackStateManager: NSObject {
    
    
    static let PlaybackStateCorrectedNotification = "PlaybackStateCorrectedNotification"
    
    private static let timeDelayInSeconds:Double = 1.0
    
    private let musicPlayer:MPMusicPlayerController
    private let audioSession = AVAudioSession.sharedInstance()
    private let stateDescriptions = ["Stopped", "Playing", "Paused", "Interrupted", "SeekingForward", "SeekingBackward"]
    private (set) var musicPlaybackState:MPMusicPlaybackState
    
    
    init(musicPlayer:MPMusicPlayerController){
        self.musicPlayer = musicPlayer
        self.musicPlaybackState = musicPlayer.playbackState
        super.init()
        self.registerForNotifications()
    }
    
    deinit {
        unregisterForNotifications()
    }
   
    
    func musicIsPlaying() -> Bool {
        return musicPlaybackState == MPMusicPlaybackState.playing
    }
    
    func otherMusicIsPlaying() -> Bool {
        return !musicIsPlaying() && audioSession.secondaryAudioShouldBeSilencedHint
    }

    func correctPlaybackState() {
        KyoozUtils.doInMainQueueAfterDelay(PlaybackStateManager.timeDelayInSeconds) { [musicPlayer = self.musicPlayer]() -> Void in
            let oldPlaybackTime = musicPlayer.currentPlaybackTime
            KyoozUtils.doInMainQueueAfterDelay(PlaybackStateManager.timeDelayInSeconds) { [weak self] ()  in
                self?.checkAgainstPlaybackTime(oldPlaybackTime)
            }
        }
    }
    
    private func checkAgainstPlaybackTime(_ playbackTime : TimeInterval) {
        let newPlaybackTime = self.musicPlayer.currentPlaybackTime
        var playbackStateCorrected:Bool = false

        if(newPlaybackTime.isNaN && playbackTime.isNaN) {
            if(self.musicPlaybackState != MPMusicPlaybackState.stopped) {
                self.musicPlaybackState = MPMusicPlaybackState.stopped
                playbackStateCorrected = true
            }
        } else {
            if(newPlaybackTime != playbackTime && self.musicPlaybackState != MPMusicPlaybackState.playing) {
                self.musicPlaybackState = MPMusicPlaybackState.playing
                playbackStateCorrected = true
            } else if (newPlaybackTime == playbackTime && self.musicPlaybackState == MPMusicPlaybackState.playing) {
                self.musicPlaybackState = MPMusicPlaybackState.paused
                playbackStateCorrected = true
            }
        }
        
        if(playbackStateCorrected) {
            var description:String?
            if musicPlaybackState.rawValue < stateDescriptions.count {
                description = stateDescriptions[musicPlaybackState.rawValue]
            }
            Logger.debug("Playback State Corrected to: \(description ?? "unknown"). oldTime:\(playbackTime), newTime:\(newPlaybackTime)")
            KyoozUtils.doInMainQueueAsync() {
                let notification = Notification(name: Notification.Name(rawValue: PlaybackStateManager.PlaybackStateCorrectedNotification), object: self)
                NotificationCenter.default.post(notification)
            }
        }

    }
    

    
    func handlePlaybackStateChanged(_ notification:Notification){
        musicPlaybackState = musicPlayer.playbackState
        correctPlaybackState()
    }
    
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(PlaybackStateManager.handlePlaybackStateChanged(_:)),
            name:NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer)
    }
    
    private func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    
}
