//
//  MPMediaCollectionExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 10/4/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

extension MPMediaEntity {
    

    var representativeItem:MPMediaItem? {
        if let collection = self as? MPMediaItemCollection {
            return collection.representativeItem
        } else {
            return self as? MPMediaItem
        }
    }
    
    func titleForGrouping(grouping:MPMediaGrouping) -> String? {
        if let playlist = self as? MPMediaPlaylist{
            if grouping == MPMediaGrouping.Playlist  {
                return playlist.name
            }
        }
        if let collection = self as? MPMediaItemCollection {
            let titleProperty = MPMediaItem.titlePropertyForGroupingType(grouping)
            guard let representativeItem = collection.representativeItem else {
                Logger.error("Could not get representative item for collection \(self.description)")
                return nil
            }
            return representativeItem.valueForProperty(titleProperty) as? String
        } else if let mediaItem = self as? MPMediaItem {
            let titleProperty = MPMediaItem.titlePropertyForGroupingType(grouping)
            return mediaItem.valueForProperty(titleProperty) as? String
        }
        
        return nil
    }
    
    var count:Int {
        if let collection = self as? MPMediaItemCollection {
            return collection.count
        } else {
            return 1
        }
    }
     
}

