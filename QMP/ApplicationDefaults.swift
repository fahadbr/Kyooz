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
        return DRMAudioQueuePlayer.instance
//        return AudioQueuePlayerImpl.instance
    }
    
    static func evaluateMinimumFetchInterval() {
        if audioQueuePlayer is DRMAudioQueuePlayer && LastFmScrobbler.instance.validSessionObtained {
            Logger.debug("FETCH INTERVAL: setting minimum fetch interval")
            UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        } else {
            Logger.debug("FETCH INTERVAL: setting fetch interval of NEVER")
            UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
        }
    }
}





