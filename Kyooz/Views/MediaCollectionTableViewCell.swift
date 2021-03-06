//
//  MediaCollectionTableViewCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 9/2/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class MediaCollectionTableViewCell: MediaLibraryTableViewCell {

    static let reuseIdentifier = "mediaEntityCellIdentifier"
    
    override func configureCellForItems(_ entity:AudioEntity, libraryGrouping:LibraryGrouping) {
        
        titleLabel.text =  entity.titleForGrouping(libraryGrouping)
        if let mediaItem = entity as? AudioTrack {
            let artist:String = mediaItem.artist ?? ""
            let album:String = mediaItem.albumTitle ?? ""
            detailsLabel.text = "\(artist) - \(album)"
            configureDRMAndCloudLabels(mediaItem)
        } else {
            let pluralText = entity.count > 1 ? "s" : ""
            detailsLabel?.text = "\(entity.count) Track\(pluralText)"
            if let mediaItem = entity.representativeTrack {
                configureDRMAndCloudLabels(mediaItem)
            }
        }
    }
    
}
