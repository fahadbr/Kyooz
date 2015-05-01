//
//  MusicPlayerContainer.swift
//  Wrapper class that will return the delegate music player for the application
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 1/10/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

struct MusicPlayerContainer {
    
    static var queueBasedMusicPlayer:QueueBasedMusicPlayer {
//        return StagedQueueBasedMusicPlayer.instance
        return QueueBasedMusicPlayerImpl.instance
    }
    
    static var defaultMusicPlayerController:MPMusicPlayerController {
        return MPMusicPlayerController.systemMusicPlayer()
    }
    
}





