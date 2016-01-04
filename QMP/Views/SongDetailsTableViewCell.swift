//
//  SongTableViewCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/26/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class SongDetailsTableViewCell: AbstractTableViewCell {

    static let normalFont = UIFont(name:ThemeHelper.defaultFontName, size:12.0)
    static let boldFont = UIFont(name:ThemeHelper.defaultFontNameMedium, size:12.0)
    
    @IBOutlet weak var albumArtImageView: UIImageView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var albumArtistAndAlbumLabel: UILabel!
    @IBOutlet weak var totalPlaybackTImeLabel: UILabel!
    @IBOutlet weak var menuButtonActionArea: UIView!
    @IBOutlet weak var menuButtonVisualView: UILabel!
    
    override var alpha:CGFloat {
        didSet {
            albumArtImageView?.alpha = alpha
            songTitleLabel?.alpha = alpha
            albumArtistAndAlbumLabel?.alpha = alpha
            totalPlaybackTImeLabel?.alpha = alpha
            menuButtonActionArea?.alpha = alpha
            menuButtonVisualView?.alpha = alpha
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        songTitleLabel.font = SongDetailsTableViewCell.boldFont
        albumArtistAndAlbumLabel.font =  SongDetailsTableViewCell.normalFont
        albumArtistAndAlbumLabel.textColor = UIColor.lightGrayColor()
        menuButtonVisualView.textColor = UIColor.lightGrayColor()
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


