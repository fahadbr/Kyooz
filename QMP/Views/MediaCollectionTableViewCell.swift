//
//  MediaCollectionTableViewCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 9/2/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class MediaCollectionTableViewCell: UITableViewCell, ConfigurableAudioTableCell {

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

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configureCellForItems(collection:MPMediaItemCollection, collectionTitleProperty:String) {
        textLabel?.text = collection.representativeItem.valueForProperty(collectionTitleProperty) as? String

        let pluralText = collection.count > 1 ? "s" : ""
        detailTextLabel?.text = "\(collection.count) Track\(pluralText)"
        detailTextLabel?.textColor = UIColor.lightGrayColor()
    }
    
}
