//
//  IPodLibraryDAO.swift
//  QMP
//
//  Created by FAHAD RIAZ on 5/3/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

struct IPodLibraryDAO {
    
    static func queryMediaItemsFromIds(persistentIds:[AnyObject]) -> [MPMediaItem]? {
        var queriedMediaItems = [AnyObject]()
        for mediaId in persistentIds {
            let mediaItem = queryMediaItemFromId(mediaId)
            if(mediaItem == nil) {
                Logger.debug("query for mediaItem with persistentID:\(mediaId) did not return anything")
                continue
            }
            queriedMediaItems.append(mediaItem!)
        }
        
        return queriedMediaItems as? [MPMediaItem]
    }
    
    static func queryMediaItemFromId(persistentId:AnyObject) -> MPMediaItem? {
//        Logger.debug("querying for mediaItem with persistentID:\(persistentId)")
        var query = MPMediaQuery()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: persistentId,
            forProperty: MPMediaItemPropertyPersistentID, comparisonType: MPMediaPredicateComparison.EqualTo))
        let tempQueryItems = query.items
        if(tempQueryItems == nil || tempQueryItems!.isEmpty) {
            return nil
        } else {
            return tempQueryItems[0] as? MPMediaItem
        }
    }
    
    
}