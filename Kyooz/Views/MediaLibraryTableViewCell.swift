//
//  MediaLibraryTableViewCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/17/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import MediaPlayer

class MediaLibraryTableViewCell : AbstractTableViewCell, AudioTableCellProtocol {
    
    @IBOutlet var cloudLabel: UILabel!
    @IBOutlet var drmLabel: UILabel!
    
    @IBOutlet var accessoryStack: UIStackView!
	
	@IBOutlet var menuButton: MenuDotsView!
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailsLabel: UILabel!
    
    weak var delegate:AudioTableCellDelegate?
    
    var shouldHideAccessoryStack:Bool = true
    var isNowPlaying:Bool = false {
        didSet {
            if isNowPlaying != oldValue {
                titleLabel.textColor = isNowPlaying ? ThemeHelper.defaultVividColor : ThemeHelper.defaultFontColor
            }
        }
    }
    
    override func initialize() {
        super.initialize()
        guard titleLabel != nil else { return }
        
        titleLabel.font = ThemeHelper.defaultFont
        let color = UIColor.lightGrayColor()
        detailsLabel.textColor = color
        cloudLabel.textColor = color
        drmLabel.textColor = color
        
        menuButton.isAccessibilityElement = true
        menuButton.accessibilityLabel = "menu button"
        menuButton.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitAllowsDirectInteraction
    }
    
    @IBAction func menuButtonPressed(sender:UIButton!) {
        let point = CGPoint(x: bounds.maxX, y: bounds.midY)
		let convertedPoint = convertPoint(point, fromCoordinateSpace: window!.screen.fixedCoordinateSpace)
        delegate?.presentActionsForCell(self, title: titleLabel.text, details: detailsLabel.text, originatingCenter: convertedPoint)
    }
    
    final func configureDRMAndCloudLabels(item:AudioTrack) {
        let cloudHidden = !item.isCloudTrack
        let drmHidden = !cloudHidden || item.assetURL != nil //hide DRM label when either showing the cloud item or if its not cloud and not drm
        
        cloudLabel.hidden = cloudHidden
        drmLabel.hidden = drmHidden
        accessoryStack.hidden = cloudHidden && drmHidden && shouldHideAccessoryStack
    }
	
	func configureCellForItems(entity: AudioEntity, libraryGrouping: LibraryGrouping) {
		//no op
	}
}