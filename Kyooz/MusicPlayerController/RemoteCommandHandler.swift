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
        
        
//        rcc.playCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            self.audioQueuePlayer.play()
//            return MPRemoteCommandHandlerStatus.Success
//        }
//        rcc.pauseCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            self.audioQueuePlayer.pause()
//            return MPRemoteCommandHandlerStatus.Success
//        }
//        rcc.togglePlayPauseCommand.enabled = shouldEnable
//        rcc.togglePlayPauseCommand.addTarget(self, action: "doNothing")
////        rcc.togglePlayPauseCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
////            if(self.audioQueuePlayer.musicIsPlaying) {
////                self.audioQueuePlayer.pause()
////            } else {
////                self.audioQueuePlayer.play()
////            }
////            return MPRemoteCommandHandlerStatus.Success
////        }
//        rcc.previousTrackCommand.enabled = shouldEnable
//        rcc.previousTrackCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            self.audioQueuePlayer.skipBackwards()
//            return MPRemoteCommandHandlerStatus.Success
//        }
//        
//        rcc.nextTrackCommand.enabled = shouldEnable
//        rcc.nextTrackCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            self.audioQueuePlayer.skipForwards()
//            return MPRemoteCommandHandlerStatus.Success
//        }
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
