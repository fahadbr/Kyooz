//
//  PlaybackStateSnapshot.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/30/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

struct PlaybackStateSnapshot {
    let playQueue:PlayQueue
    let currentPlaybackTime:Float
    
    var persistableSnapshot:PlaybackStatePersistableSnapshot {
        return PlaybackStatePersistableSnapshot(snapshot: self)
    }
}

final class PlaybackStatePersistableSnapshot : NSObject, NSSecureCoding {
    private static let contextKey = "contextKey"
    private static let timeKey = "timeKey"
	
	private typealias This = PlaybackStatePersistableSnapshot
	
    static var supportsSecureCoding: Bool {
        return true
    }
    
    let snapshot:PlaybackStateSnapshot
    
    init(snapshot:PlaybackStateSnapshot) {
        self.snapshot = snapshot
    }
    
    required init?(coder aDecoder: NSCoder) {
		NSKeyedUnarchiver.setClass(PlayQueuePersistableWrapper.self, forClassName: "Kyooz.NowPlayingQueuePersistableContext")
        guard let persistedContext = aDecoder.decodeObject(of: PlayQueuePersistableWrapper.self, forKey: This.contextKey) else {
			let type = ApplicationDefaults.audioQueuePlayer.type
            self.snapshot = PlaybackStateSnapshot(playQueue: PlayQueue(originalQueue: [AudioTrack](),
                                                                       forType: type),
                                                  currentPlaybackTime: 0)
            return
        }
        
        let playbackTime = aDecoder.decodeFloat(forKey: This.timeKey)
        self.snapshot = PlaybackStateSnapshot(playQueue: persistedContext.context, currentPlaybackTime: playbackTime)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(snapshot.playQueue.persistableContext, forKey: PlaybackStatePersistableSnapshot.contextKey)
        aCoder.encode(snapshot.currentPlaybackTime, forKey: PlaybackStatePersistableSnapshot.timeKey)
    }
}
