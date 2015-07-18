//
//  ApplicationDefaults.swift
//  Class that will return the application level default implementations of certain classes or interfaces
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/10/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

struct ApplicationDefaults {
    
    static var audioQueuePlayer:AudioQueuePlayer {
//        return StagedAudioQueuePlayer.instance
        return DRMAudioQueuePlayer.instance
//        return AudioQueuePlayerImpl.instance
    }
    
    static var defaultMusicPlayerController:MPMusicPlayerController {
        return MPMusicPlayerController.systemMusicPlayer()
    }
    
//    static let audioController:AudioController = SimpleAudioController.instance
    static let audioController:AudioController = AudioEngineController.instance
    
}





