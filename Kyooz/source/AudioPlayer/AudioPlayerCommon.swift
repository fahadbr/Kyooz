//
//  QueueIndexDeriver.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 10/15/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import MediaPlayer

enum AudioPlayerCommon {
    static let groupId = "group.kyooz"
    static let queueKey = "queueIds"
    static let lastPersistedIndexKey = "lastPersistedIndex"
    
}

func deriveQueueIndex(musicPlayer: MPMusicPlayerController,
                      lowestIndexPersisted: Int,
                      queueSize: Int) -> Int {
 
    let i = musicPlayer.indexOfNowPlayingItem + lowestIndexPersisted
    return queueSize == 0 ? i : i % queueSize
}
