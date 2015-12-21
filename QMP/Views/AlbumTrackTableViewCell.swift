//
//  AlbumTrackTableViewCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 9/2/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class AlbumTrackTableViewCell: AbstractTableViewCell {

    static let reuseIdentifier = "albumTrackTableViewCell"
    
    @IBOutlet weak var trackNumber: UILabel!
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var trackDetails: UILabel!
    @IBOutlet weak var trackDuration: UILabel!
    
    
    var isNowPlayingItem:Bool = false {
        didSet {
            if isNowPlayingItem != oldValue {
                if isNowPlayingItem {
                    trackTitle.textColor = ThemeHelper.defaultVividColor
                } else {
                    trackTitle.textColor = ThemeHelper.defaultFontColor
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let color = UIColor.lightGrayColor()
        trackNumber.textColor = color
        trackDetails.textColor = color
        trackDuration.textColor = color
        // Initialization code
    }
    
    func configureCellForItem(mediaItem:AudioTrack) {
        trackNumber.text = mediaItem.albumTrackNumber > 0 ? "\(mediaItem.albumTrackNumber)" : nil
        trackTitle.text = mediaItem.trackTitle
        trackDetails.text = mediaItem.artist
        trackDuration.text = MediaItemUtils.getTimeRepresentation(mediaItem.playbackDuration)
    }
}
