//
//  MediaLibraryTableViewCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/17/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import MediaPlayer

class MediaLibraryTableViewCell : AbstractTableViewCell {
    
    @IBOutlet var cloudLabel: UILabel!
    @IBOutlet var drmLabel: UILabel!
    
    @IBOutlet var accessoryStack: UIStackView!
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailsLabel: UILabel!
    
    weak var delegate:ConfigurableAudioTableCellDelegate?
    
    var indexPath:NSIndexPath!
    var shouldHideAccessoryStack:Bool = true
    
    var isNowPlayingItem:Bool = false {
        didSet {
            if isNowPlayingItem != oldValue {
                if isNowPlayingItem {
                    titleLabel.textColor = ThemeHelper.defaultVividColor
                } else {
                    titleLabel.textColor = ThemeHelper.defaultFontColor
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = ThemeHelper.defaultFont
        detailsLabel.textColor = UIColor.lightGrayColor()
        cloudLabel.textColor = UIColor.lightGrayColor()
        drmLabel.textColor = UIColor.lightGrayColor()
    }
    
    @IBAction func menuButtonPressed(sender:UIButton!) {
        delegate?.presentActionsForIndexPath(indexPath, title: titleLabel.text, details: detailsLabel.text)
    }
    
    final func configureDRMAndCloudLabels(item:MPMediaItem) {
        let cloudHidden = !item.cloudItem
        let drmHidden = !cloudHidden || item.assetURL != nil //hide DRM label when either showing the cloud item or if its not cloud and not drm
        
        cloudLabel.hidden = cloudHidden
        drmLabel.hidden = drmHidden
        accessoryStack.hidden = cloudHidden && drmHidden && shouldHideAccessoryStack
    }
}