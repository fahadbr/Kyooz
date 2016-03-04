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
    
    static let audioQueuePlayer:AudioQueuePlayer = {
        let value = AudioQueuePlayerType(rawValue: NSUserDefaults.standardUserDefaults().integerForKey(UserDefaultKeys.AudioQueuePlayer)) ?? AudioQueuePlayerType.Default
        let player:AudioQueuePlayer
        switch value {
        case .AppleDRM:
            Logger.debug("Loading DRMAudioQueuePlayer")
            player = DRMAudioQueuePlayer.instance
        case .Default:
            Logger.debug("Loading AudioQueuePlayerImpl")
            player = AudioQueuePlayerImpl.instance
        }
        player.delegate = AudioQueuePlayerDelegateImpl()
        return player
    }()
	
	static let audioEntitySearchViewController = AudioEntitySearchViewController()
    
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





