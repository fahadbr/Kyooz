//
//  UserDefaultValues.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/18/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

struct UserDefaultKeys {
    static let AudioQueuePlayer = "AUDIO_QUEUE_PLAYER"
    static let ReduceAnimations = "ReduceAnimations"
    static let AllMusicBaseGroup = "AllMusicBaseGroup"
	static let LastFmSessionKey = "SESSION_KEY"
	static let LastFmUsernameKey = "USERNAME_KEY"
    
}

enum AudioQueuePlayerType : Int {
    case Default, AppleDRM
}