//
//  TempDataPersistor.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 4/4/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

struct TempDataDAO {
    
    private static let tempDirectory = NSTemporaryDirectory()
    private static let nowPlayingQueueFileName = tempDirectory.stringByAppendingPathComponent("nowPlayingQueue.txt")
    
    static func persistNowPlayingQueueToTempStorage(mediaItems:[MPMediaItem]?) {
        if(mediaItems == nil || mediaItems!.count == 0) {
            return
        }
        
//        let pIds = (mediaItems as NSArray).valueForKey("persistentID") as NSArray
//        pIds.writeToFile(nowPlayingQueueFileName, atomically: true)
        
        var persistentIds = [NSNumber]()
        for mediaItem in mediaItems! {
            println("persisting mediaItem with persistentID:\(mediaItem.persistentID)")
            persistentIds.append(NSNumber(unsignedLongLong: mediaItem.persistentID))
        }
        
        let nsPersistentIds = persistentIds as NSArray
        nsPersistentIds.writeToFile(nowPlayingQueueFileName, atomically: true)
        
    }
    
    static func getNowPlayingQueueFromTempStorage() -> [MPMediaItem]? {
        if(!NSFileManager.defaultManager().fileExistsAtPath(nowPlayingQueueFileName)) {
            return nil
        }
        let persistedMediaIds = NSArray(contentsOfFile: nowPlayingQueueFileName) as! [AnyObject]
        
        var queriedMediaItems = [AnyObject]()
        

        for mediaId in persistedMediaIds {
            println("querying for mediaItem with persistentID:\(mediaId)")
            var query = MPMediaQuery()
            query.addFilterPredicate(MPMediaPropertyPredicate(value: mediaId,
                forProperty: MPMediaItemPropertyPersistentID, comparisonType: MPMediaPredicateComparison.EqualTo))
            let tempQueryItems = query.items
            if(tempQueryItems == nil || tempQueryItems!.isEmpty) {
                println("query for mediaItem with persistentID:\(mediaId) did not return anything")
                continue
            }
            queriedMediaItems.extend(tempQueryItems)
        }
        
        return queriedMediaItems as? [MPMediaItem]
    }
    
}