//
//  IPodLibraryDAO.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/3/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

struct IPodLibraryDAO {
    
    static func queryMediaItemsFromIds(persistentIds:[AnyObject]) -> [AudioTrack]? {
        var queriedMediaItems = [AnyObject]()
        KyoozUtils.performWithMetrics(blockDescription: "Query of List of IDs from iPod Library") {
            for mediaId in persistentIds {
                let mediaItem = queryMediaItemFromId(mediaId)
                if(mediaItem == nil) {
                    Logger.debug("query for mediaItem with persistentID:\(mediaId) did not return anything")
                    continue
                }
                queriedMediaItems.append(mediaItem!)
            }
        }
        return queriedMediaItems as? [AudioTrack]
    }
    
    static func queryMediaItemFromId(persistentId:AnyObject) -> AudioTrack? {
        let query = MPMediaQuery()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: persistentId, forProperty: MPMediaItemPropertyPersistentID))
        return query.items?.first
    }
    
    
}