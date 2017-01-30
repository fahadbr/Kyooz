//
//  RemotePlaybackEventHandler.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 10/8/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

class RemoteCommandHandler : NSObject {
    
    let rcc = MPRemoteCommandCenter.shared()
    let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    override init() {
        super.init()
        Logger.debug("registering for remote commands")
        registerForRemoteCommands()
    }
    
    deinit {
        unregisterForRemoteCommands()
    }

    //MARK: Remote Command Center Registration
    private func registerForRemoteCommands() {
        let shouldEnable = true
        rcc.previousTrackCommand.isEnabled = shouldEnable
        rcc.nextTrackCommand.isEnabled = shouldEnable
        rcc.playCommand.isEnabled = shouldEnable
        rcc.nextTrackCommand.addTarget(self, action: #selector(RemoteCommandHandler.nextTrack))
        rcc.previousTrackCommand.addTarget(self, action: #selector(RemoteCommandHandler.previousTrack))
        rcc.playCommand.addTarget(self, action: #selector(RemoteCommandHandler.play))
        
    }
    
    func nextTrack() {
        audioQueuePlayer.skipForwards()
    }
    
    func previousTrack() {
        audioQueuePlayer.skipBackwards(false)
    }
    
    
    func play() {
        rcc.playCommand.isEnabled = true
        if audioQueuePlayer.musicIsPlaying {
            audioQueuePlayer.pause()
        } else {
            audioQueuePlayer.play()
        }
    }
    
    private func unregisterForRemoteCommands() {
        rcc.playCommand.removeTarget(self)
        rcc.pauseCommand.removeTarget(self)
        rcc.togglePlayPauseCommand.removeTarget(self)
        rcc.previousTrackCommand.removeTarget(self)
        rcc.nextTrackCommand.removeTarget(self)
    }


}
