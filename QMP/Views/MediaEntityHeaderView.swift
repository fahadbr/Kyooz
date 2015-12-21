//
//  LibraryGroupingHeaderView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/19/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

class MediaEntityHeaderView: UIView {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var button: UIButton!
    
    var menuButtonBlock:(()->())?
    private var menuActive:Bool = false

    @IBAction func menuButtonPressed(sender: UIButton) {
        menuActive = !menuActive
        menuButtonBlock?()
        button.setTitle(menuActive ? "CANCEL" : "SELECT", forState: .Normal)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

class AlbumHeaderView : MediaEntityHeaderView {
    
    @IBOutlet weak var albumImage: UIImageView!
    
    @IBOutlet weak var albumTitleLabel: UILabel!
    @IBOutlet weak var albumArtistLabel: UILabel!
    @IBOutlet weak var albumDetailsLabel: UILabel!
    @IBOutlet weak var albumDurationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mainView = self
        albumDurationLabel.textColor = UIColor.lightGrayColor()
        albumDetailsLabel.textColor = UIColor.lightGrayColor()
    }
    
    
}
