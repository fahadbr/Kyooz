//
//  MPMediaQueryExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 10/4/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

extension MPMediaQuery {
    static func albumArtistsQuery() -> MPMediaQuery {
        let query = MPMediaQuery()
        query.groupingType = MPMediaGrouping.AlbumArtist
        return query
    }
    
    func shouldQueryCloudItems(shouldQueryCloudItems:Bool) -> MPMediaQuery {
        if(!shouldQueryCloudItems) {
            self.addFilterPredicate(MPMediaPropertyPredicate(value: shouldQueryCloudItems, forProperty: MPMediaItemPropertyIsCloudItem))
        }
        return self
    }
    
    func setMusicOnly() -> MPMediaQuery {
        self.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.Music.rawValue, forProperty: MPMediaItemPropertyMediaType))
        return self
    }
}