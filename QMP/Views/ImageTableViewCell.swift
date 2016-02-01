//
//  AlbumTableViewCell.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/30/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class ImageTableViewCell: MediaLibraryTableViewCell, ConfigurableAudioTableCell{
    
    static let reuseIdentifier = "imageTableViewCell"
    
    @IBOutlet weak var albumArtwork: UIImageView!

    
    func configureCellForItems(entity:AudioEntity, libraryGrouping:LibraryGrouping) {
        
        titleLabel.text = entity.titleForGrouping(libraryGrouping)
        
        let pluralText = entity.count > 1 ? "s" : ""
        var text = "\(entity.count) Track\(pluralText)"
        if let mediaItem = entity.representativeItem as? MPMediaItem {
            if let releaseDate = MediaItemUtils.getReleaseDateString(mediaItem) {
                text = text + " • \(releaseDate)"
            }
            configureDRMAndCloudLabels(mediaItem)
        }
        detailsLabel.text = text
        KyoozUtils.doInMainQueueAsync() {
            let albumArtworkTemp = entity.representativeItem?.artwork?.imageWithSize(self.albumArtwork.frame.size)
            if(albumArtworkTemp == nil) {
                self.albumArtwork?.image = ImageContainer.defaultAlbumArtworkImage
            } else {
                self.albumArtwork?.image = albumArtworkTemp
            }
        }
    
    }
    
}
