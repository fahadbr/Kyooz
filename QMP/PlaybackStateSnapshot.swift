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
    let indexOfNowPlayingItem:Int
    
    var persistableSnapshot:PlaybackStatePersistableSnapshot {
        return PlaybackStatePersistableSnapshot(snapshot: self)
    }
    
    init(nowPlayingQueueContext:NowPlayingQueueContext,
        currentPlaybackTime:Float,
        indexOfNowPlayingItem:Int) {
            self.nowPlayingQueueContext = nowPlayingQueueContext
            self.currentPlaybackTime = currentPlaybackTime
            self.indexOfNowPlayingItem = indexOfNowPlayingItem
    }

}

final class PlaybackStatePersistableSnapshot : NSObject, NSSecureCoding {
    private static let contextKey = "contextKey"
    private static let timeKey = "timeKey"
    private static let indexKey = "indexKey"
    
    static func supportsSecureCoding() -> Bool {
        return true
    }
    
    let snapshot:PlaybackStateSnapshot
    
    init(snapshot:PlaybackStateSnapshot) {
        self.snapshot = snapshot
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let persistedContext = aDecoder.decodeObjectOfClass(NowPlayingQueuePersistableContext.self, forKey: PlaybackStatePersistableSnapshot.contextKey) else {
            self.snapshot = PlaybackStateSnapshot(nowPlayingQueueContext: NowPlayingQueueContext(originalQueue: [AudioTrack]()), currentPlaybackTime: 0, indexOfNowPlayingItem: 0)
            return
        }
        
        let playbackTime = aDecoder.decodeFloatForKey(PlaybackStatePersistableSnapshot.timeKey)
        let index = aDecoder.decodeIntegerForKey(PlaybackStatePersistableSnapshot.indexKey)
        self.snapshot = PlaybackStateSnapshot(nowPlayingQueueContext: persistedContext.context, currentPlaybackTime: playbackTime, indexOfNowPlayingItem: index)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(snapshot.nowPlayingQueueContext.persistableContext, forKey: PlaybackStatePersistableSnapshot.contextKey)
        aCoder.encodeFloat(snapshot.currentPlaybackTime, forKey: PlaybackStatePersistableSnapshot.timeKey)
        aCoder.encodeInteger(snapshot.indexOfNowPlayingItem, forKey: PlaybackStatePersistableSnapshot.indexKey)
    }
}
