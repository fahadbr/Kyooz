//
//  PlayCountIteratorOperation.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/16/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

final class PlayCountIteratorOperation: NSOperation {
    
    private let lastFmScrobbler = LastFmScrobbler.instance
    
    private let oldPlayCounts:[NSNumber:Int]
    private (set) var newPlayCounts = [NSNumber:Int]()
    
    private let playCountCompletionBlock:(([NSNumber:Int])->())?
    
    init(oldPlayCounts:[NSNumber:Int], playCountCompletionBlock:(([NSNumber:Int])->())?) {
        self.oldPlayCounts = oldPlayCounts
        self.playCountCompletionBlock = playCountCompletionBlock
        super.init()
    }
    
    deinit {
        Logger.debug("deinit of playcount op")
    }
    
    override func main() {
        KyoozUtils.performWithMetrics(blockDescription: "iterateThroughPlaycounts") {
            self.iterateThroughPlaycounts()
        }
    }
    
    private func iterateThroughPlaycounts() {
        guard let items = MPMediaQuery.songsQuery().items else {
            Logger.debug("no items found in library")
            return
        }
        Logger.debug("starting iteration through play counts")
        
        for item in items {
            if cancelled { return }
            
            let newCount = item.playCount
            let key = NSNumber(unsignedLongLong: item.persistentID)
            if let oldCount = oldPlayCounts[key] {
                if newCount > oldCount {
                    let timeStamp = item.lastPlayedDate?.timeIntervalSince1970 ?? NSDate().timeIntervalSince1970
                    for _ in oldCount..<newCount {
                        lastFmScrobbler.addToScrobbleCache(item, timeStampToScrobble: timeStamp)
                    }
                }
            }
            
            newPlayCounts[key] = newCount
        }
        
        if !cancelled {
            playCountCompletionBlock?(newPlayCounts)
        }
    }
    
}
