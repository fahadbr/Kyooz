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
    
    private let oldPlayCounts:NSDictionary
    private let newPlayCounts = NSMutableDictionary()
    private let playCountCompletionBlock:((NSDictionary)->())?
    
    init(oldPlayCounts:NSDictionary, playCountCompletionBlock:((NSDictionary)->())?) {
        self.oldPlayCounts = oldPlayCounts
        self.playCountCompletionBlock = playCountCompletionBlock
        super.init()
    }
    
//    deinit {
//        Logger.debug("deinit of playcount op")
//    }
    
    override func main() {
        iterateThroughPlaycounts()
    }
    
    private func iterateThroughPlaycounts() {
        guard let items = MPMediaQuery.songsQuery().items else {
            Logger.debug("no items found in library")
            return
        }
        
        for item in items {
            if cancelled { return }
            
            let newCount = item.playCount
            let key = NSNumber(unsignedLongLong: item.persistentID)
            
            if let oldCount = (oldPlayCounts.objectForKey(key) as? NSNumber)?.integerValue {
                if newCount > oldCount {
                    let timeStamp = floor(item.lastPlayedDate?.timeIntervalSince1970 ?? NSDate().timeIntervalSince1970)
                    for i in 0..<(newCount-oldCount) {
                        lastFmScrobbler.addToScrobbleCache(item, timeStampToScrobble: timeStamp + Double(i))
                    }
                }
            }
            
            newPlayCounts.setObject(NSNumber(integer: newCount), forKey: key)
        }
        
        if !cancelled {
            playCountCompletionBlock?(newPlayCounts)
        }
    }
    
}
