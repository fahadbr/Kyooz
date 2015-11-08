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
    
    let rcc = MPRemoteCommandCenter.sharedCommandCenter()
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
        rcc.previousTrackCommand.enabled = shouldEnable
        rcc.nextTrackCommand.enabled = shouldEnable
        rcc.playCommand.enabled = shouldEnable
        rcc.nextTrackCommand.addTarget(self, action: "nextTrack")
        rcc.previousTrackCommand.addTarget(self, action: "previousTrack")
        rcc.playCommand.addTarget(self, action: "play")
        
        
//        remoteCommandCenter.playCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            self.audioQueuePlayer.play()
//            return MPRemoteCommandHandlerStatus.Success
//        }
//        remoteCommandCenter.pauseCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            self.audioQueuePlayer.pause()
//            return MPRemoteCommandHandlerStatus.Success
//        }
//        remoteCommandCenter.togglePlayPauseCommand.enabled = shouldEnable
//        remoteCommandCenter.togglePlayPauseCommand.addTarget(self, action: "doNothing")
////        remoteCommandCenter.togglePlayPauseCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
////            if(self.audioQueuePlayer.musicIsPlaying) {
////                self.audioQueuePlayer.pause()
////            } else {
////                self.audioQueuePlayer.play()
////            }
////            return MPRemoteCommandHandlerStatus.Success
////        }
//        remoteCommandCenter.previousTrackCommand.enabled = shouldEnable
//        remoteCommandCenter.previousTrackCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            self.audioQueuePlayer.skipBackwards()
//            return MPRemoteCommandHandlerStatus.Success
//        }
//        
//        remoteCommandCenter.nextTrackCommand.enabled = shouldEnable
//        remoteCommandCenter.nextTrackCommand.addTargetWithHandler { [unowned self](remoteCommandEvent:MPRemoteCommandEvent!) -> MPRemoteCommandHandlerStatus in
//            self.audioQueuePlayer.skipForwards()
//            return MPRemoteCommandHandlerStatus.Success
//        }
    }
    
    func nextTrack() {
        audioQueuePlayer.skipForwards()
    }
    
    func previousTrack() {
        audioQueuePlayer.skipBackwards()
    }
    
    
    func play() {
        rcc.playCommand.enabled = true
    }
    
    private func unregisterForRemoteCommands() {
        rcc.playCommand.removeTarget(self)
        rcc.pauseCommand.removeTarget(self)
        rcc.togglePlayPauseCommand.removeTarget(self)
        rcc.previousTrackCommand.removeTarget(self)
        rcc.nextTrackCommand.removeTarget(self)
    }


}