//
//  AlbumTableViewCell.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/30/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class ImageTableViewCell: UITableViewCell, ConfigurableAudioTableCell{
    
    static let reuseIdentifier = "imageTableViewCell"
    
    @IBOutlet weak var albumArtwork: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var details: UILabel!
    
    var isNowPlayingItem:Bool = false {
        didSet {
            if isNowPlayingItem != oldValue {
                if isNowPlayingItem {
                    title.textColor = ThemeHelper.defaultVividColor
                } else {
                    title.textColor = ThemeHelper.defaultFontColor
                }
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        details?.textColor = UIColor.lightGrayColor()
        accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCellForItems(entity:MPMediaEntity, mediaGroupingType:MPMediaGrouping) {
        
        title?.text = entity.titleForGrouping(mediaGroupingType)
        
        let pluralText = entity.count > 1 ? "s" : ""
        var text = "\(entity.count) Track\(pluralText)"
        if let mediaItem = entity.representativeItem, let releaseDate = mediaItem.releaseDate {
            text = text + " • \(releaseDate)"
        }
        details?.text = text
        
        let albumArtworkTemp = entity.representativeItem?.artwork?.imageWithSize(albumArtwork.frame.size)
        if(albumArtworkTemp == nil) {
            albumArtwork?.image = ImageContainer.defaultAlbumArtworkImage
        } else {
            albumArtwork?.image = albumArtworkTemp
        }
    
    }
    
}
