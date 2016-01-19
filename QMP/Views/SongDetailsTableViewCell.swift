//
//  SongTableViewCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/26/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class SongDetailsTableViewCell: AbstractTableViewCell {

    static let reuseIdentifier = "songDetailsTableViewCell"
    
    private static let normalFont = UIFont(name:ThemeHelper.defaultFontName, size:12.0)
    private static let boldFont = UIFont(name:ThemeHelper.defaultFontNameMedium, size:12.0)
    
    @IBOutlet var albumArtImageView: UIImageView!
    @IBOutlet var songTitleLabel: UILabel!
    @IBOutlet var albumArtistAndAlbumLabel: UILabel!
    @IBOutlet var totalPlaybackTImeLabel: UILabel!
    @IBOutlet var menuButton:UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        songTitleLabel.font = SongDetailsTableViewCell.boldFont
        albumArtistAndAlbumLabel.font =  SongDetailsTableViewCell.normalFont
        albumArtistAndAlbumLabel.textColor = UIColor.lightGrayColor()
        menuButton.userInteractionEnabled = false
    }
    
    func configureTextLabelsForMediaItem(mediaItem:AudioTrack, isNowPlayingItem:Bool) {
        songTitleLabel.text = mediaItem.trackTitle
        var details = [String]()
        if let albumArtist = mediaItem.albumArtist {
            details.append(albumArtist)
        } else if let artist = mediaItem.artist {
            details.append(artist)
        }
        if let albumTitle = mediaItem.albumTitle {
            details.append(albumTitle)
        }
        
        albumArtistAndAlbumLabel.text = details.joinWithSeparator(" - ")
        totalPlaybackTImeLabel.text = MediaItemUtils.getTimeRepresentation(mediaItem.playbackDuration)
        songTitleLabel.textColor = isNowPlayingItem ? ThemeHelper.defaultVividColor : ThemeHelper.defaultFontColor
    }
    
}


