//
//  MediaCollectionTableViewCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 9/2/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class MediaCollectionTableViewCell: AbstractTableViewCell, ConfigurableAudioTableCell {

    static let reuseIdentifier = "mediaEntityCellIdentifier"
    
    var isNowPlayingItem:Bool = false {
        didSet {
            if isNowPlayingItem != oldValue {
                if isNowPlayingItem {
                    textLabel?.textColor = ThemeHelper.defaultVividColor
                } else {
                    textLabel?.textColor = ThemeHelper.defaultFontColor
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.Subtitle, reuseIdentifier: reuseIdentifier)
        textLabel?.font = ThemeHelper.defaultFont
        textLabel?.textColor = ThemeHelper.defaultFontColor
        detailTextLabel?.font = UIFont(name: ThemeHelper.defaultFontName, size: 12)
        detailTextLabel?.textColor = UIColor.lightGrayColor()
        
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configureCellForItems(entity:MPMediaEntity, mediaGroupingType:MPMediaGrouping) {
        
        textLabel?.text =  entity.titleForGrouping(mediaGroupingType)
        if let mediaItem = entity as? MPMediaItem {
            let artist:String = mediaItem.artist == nil ?  "" : mediaItem.artist!
            let album:String = mediaItem.albumTitle == nil ?  "" : mediaItem.albumTitle!
            detailTextLabel?.text = "\(artist) - \(album)"
            accessoryType = UITableViewCellAccessoryType.None
        } else {
            let pluralText = entity.count > 1 ? "s" : ""
            detailTextLabel?.text = "\(entity.count) Track\(pluralText)"
            accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        }
    }
    
}
