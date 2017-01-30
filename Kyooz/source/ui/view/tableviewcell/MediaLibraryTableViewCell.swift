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
        let color = UIColor.lightGray
        detailsLabel.textColor = color
        cloudLabel.textColor = color
        drmLabel.textColor = color
        
        menuButton.isAccessibilityElement = true
        menuButton.accessibilityLabel = "menu button"
        menuButton.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitAllowsDirectInteraction
    }
    
    @IBAction func menuButtonPressed(_ sender:UIButton!) {
        let point = CGPoint(x: bounds.maxX, y: bounds.midY)
		let convertedPoint = convert(point, from: window!.screen.fixedCoordinateSpace)
        delegate?.presentActionsForCell(self, title: titleLabel.text, details: detailsLabel.text, originatingCenter: convertedPoint)
    }
    
    final func configureDRMAndCloudLabels(_ item:AudioTrack) {
        let cloudHidden = !item.isCloudTrack
        let drmHidden = !cloudHidden || item.assetURL != nil //hide DRM label when either showing the cloud item or if its not cloud and not drm
        
        cloudLabel.isHidden = cloudHidden
        drmLabel.isHidden = drmHidden
        accessoryStack.isHidden = cloudHidden && drmHidden && shouldHideAccessoryStack
    }
	
	func configureCellForItems(_ entity: AudioEntity, libraryGrouping: LibraryGrouping) {
		//no op
	}
}
