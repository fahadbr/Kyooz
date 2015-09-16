//
//  AlbumTableViewCell.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/30/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class AlbumTableViewCell: UITableViewCell, ConfigurableAudioTableCell{
    
    
    @IBOutlet weak var albumArtwork: UIImageView!
    @IBOutlet weak var albumTitle: UILabel!
    @IBOutlet weak var albumDetails: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        albumDetails?.textColor = UIColor.lightGrayColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCellForItems(collection:MPMediaItemCollection, collectionTitleProperty:String) {
        albumTitle?.text = collection.representativeItem.albumTitle
        
        let pluralText = collection.count > 1 ? "s" : ""
        albumDetails?.text = "\(collection.count) Track\(pluralText)"
        
        let albumArtworkTemp = collection.representativeItem?.artwork?.imageWithSize(albumArtwork.frame.size)
        if(albumArtworkTemp == nil) {
            albumArtwork?.image = ImageContainer.defaultAlbumArtworkImage
        } else {
            albumArtwork?.image = albumArtworkTemp
        }
    }
    
}
