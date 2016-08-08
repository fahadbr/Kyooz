//
//  PlaybackStateSnapshot.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/30/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

struct PlaybackStateSnapshot {
    let nowPlayingQueueContext:NowPlayingQueueContext
    let currentPlaybackTime:Float
    
    var persistableSnapshot:PlaybackStatePersistableSnapshot {
        return PlaybackStatePersistableSnapshot(snapshot: self)
    }
}

final class PlaybackStatePersistableSnapshot : NSObject, NSSecureCoding {
    private static let contextKey = "contextKey"
    private static let timeKey = "timeKey"
    
    static var supportsSecureCoding: Bool {
        return true
    }
    
    let snapshot:PlaybackStateSnapshot
    
    init(snapshot:PlaybackStateSnapshot) {
        self.snapshot = snapshot
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let persistedContext = aDecoder.decodeObject(of: NowPlayingQueuePersistableContext.self, forKey: PlaybackStatePersistableSnapshot.contextKey) else {
			let type = ApplicationDefaults.audioQueuePlayer.type
            self.snapshot = PlaybackStateSnapshot(nowPlayingQueueContext: NowPlayingQueueContext(originalQueue: [AudioTrack](), forType: type), currentPlaybackTime: 0)
            return
        }
        
        let playbackTime = aDecoder.decodeFloat(forKey: PlaybackStatePersistableSnapshot.timeKey)
        self.snapshot = PlaybackStateSnapshot(nowPlayingQueueContext: persistedContext.context, currentPlaybackTime: playbackTime)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(snapshot.nowPlayingQueueContext.persistableContext, forKey: PlaybackStatePersistableSnapshot.contextKey)
        aCoder.encode(snapshot.currentPlaybackTime, forKey: PlaybackStatePersistableSnapshot.timeKey)
    }
}
