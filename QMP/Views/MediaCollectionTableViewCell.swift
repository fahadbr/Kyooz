//
//  MediaCollectionTableViewCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 9/2/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class MediaCollectionTableViewCell: MediaLibraryTableViewCell, ConfigurableAudioTableCell {

    static let reuseIdentifier = "mediaEntityCellIdentifier"
    
    func configureCellForItems(entity:MPMediaEntity, mediaGroupingType:MPMediaGrouping) {
        
        titleLabel.text =  entity.titleForGrouping(mediaGroupingType)
        if let mediaItem = entity as? MPMediaItem {
            let artist:String = mediaItem.artist == nil ?  "" : mediaItem.artist!
            let album:String = mediaItem.albumTitle == nil ?  "" : mediaItem.albumTitle!
            detailsLabel.text = "\(artist) - \(album)"
            configureDRMAndCloudLabels(mediaItem)
        } else {
            let pluralText = entity.count > 1 ? "s" : ""
            detailsLabel?.text = "\(entity.count) Track\(pluralText)"
            if let mediaItem = entity.representativeItem {
                configureDRMAndCloudLabels(mediaItem)
            }
        }
    }
    
}
