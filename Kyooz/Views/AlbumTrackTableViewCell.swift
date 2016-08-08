//
//  AlbumTrackTableViewCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 9/2/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class AlbumTrackTableViewCell: MediaLibraryTableViewCell {

    static let reuseIdentifier = "albumTrackTableViewCell"
    
    @IBOutlet weak var trackNumber: UILabel!
    @IBOutlet weak var trackDuration: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let color = UIColor.lightGray
        trackNumber.textColor = color
        trackDuration.textColor = color
        shouldHideAccessoryStack = false
    }
    
    override func configureCellForItems(_ entity:AudioEntity, libraryGrouping:LibraryGrouping) {
        guard let mediaItem = entity as? AudioTrack else {
            return
        }
        
        trackNumber.text = mediaItem.albumTrackNumber > 0 ? "\(mediaItem.albumTrackNumber)" : nil
        titleLabel.text = mediaItem.trackTitle
        detailsLabel.text = mediaItem.artist
        trackDuration.text = MediaItemUtils.getTimeRepresentation(mediaItem.playbackDuration)
        configureDRMAndCloudLabels(mediaItem)
    }

}
