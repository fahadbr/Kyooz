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
	
	static func audioQueryForGrouping(grouping:MPMediaGrouping, isCompilation:Bool = false) -> MPMediaQuery {
		let query = MPMediaQuery()
		query.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.AnyAudio.rawValue, forProperty: MPMediaItemPropertyMediaType))
		query.groupingType = grouping
		if isCompilation {
			query.addFilterPredicate(MPMediaPropertyPredicate(value: true, forProperty: MPMediaItemPropertyIsCompilation))
		}
		return query
	}
    
    func shouldQueryCloudItems(shouldQueryCloudItems:Bool) -> MPMediaQuery {
        if(!shouldQueryCloudItems) {
            self.addFilterPredicate(MPMediaPropertyPredicate(value: shouldQueryCloudItems, forProperty: MPMediaItemPropertyIsCloudItem))
        }
        return self
    }
	
}