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
    
    var isNowPlaying:Bool = false {
        didSet {
            if isNowPlaying != oldValue {
                titleLabel.textColor = isNowPlaying ? ThemeHelper.defaultVividColor : ThemeHelper.defaultFontColor
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = ThemeHelper.defaultFont
        let color = UIColor.lightGrayColor()
        detailsLabel.textColor = color
        cloudLabel.textColor = color
        drmLabel.textColor = color
    }
    
    @IBAction func menuButtonPressed(sender:UIButton!) {
        delegate?.presentActionsForIndexPath(indexPath, title: titleLabel.text, details: detailsLabel.text)
    }
    
    final func configureDRMAndCloudLabels(item:AudioTrack) {
        let cloudHidden = !item.isCloudTrack
        let drmHidden = !cloudHidden || item.assetURL != nil //hide DRM label when either showing the cloud item or if its not cloud and not drm
        
        cloudLabel.hidden = cloudHidden
        drmLabel.hidden = drmHidden
        accessoryStack.hidden = cloudHidden && drmHidden && shouldHideAccessoryStack
    }
}