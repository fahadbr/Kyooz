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
        let value = AudioQueuePlayerType(rawValue: UserDefaults.standard.integer(forKey: UserDefaultKeys.AudioQueuePlayer)) ?? AudioQueuePlayerType.default
        let player:AudioQueuePlayer
        switch value {
        case .appleDRM:
            player = DRMAudioQueuePlayer.instance
        case .default:
            player = AudioQueuePlayerImpl.instance
        }
        
        Logger.debug("Loading \(type(of: player)) as the application audio player")
        player.delegate = AudioQueuePlayerDelegateImpl()
        return player
    }()

    static func evaluateMinimumFetchInterval() {

        if audioQueuePlayer is DRMAudioQueuePlayer && LastFmScrobbler.instance.validSessionObtained {
            Logger.debug("FETCH INTERVAL: setting minimum fetch interval")
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        } else {
            Logger.debug("FETCH INTERVAL: setting fetch interval of NEVER")
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
        }
    }

	static func initializeData() {
		#if MOCK_DATA
			Logger.debug("launching with test data")
			TestDataGenerator.generateData()
		#endif
	}


}
