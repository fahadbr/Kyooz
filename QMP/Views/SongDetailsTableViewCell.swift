//
//  SongTableViewCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/26/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class SongDetailsTableViewCell: UITableViewCell {

    static let normalFont = UIFont(name:ThemeHelper.defaultFontName, size:12.0)
    static let boldFont = UIFont(name:ThemeHelper.defaultFontNameBold, size:12.0)
    
    @IBOutlet weak var albumArtImageView: UIImageView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var albumArtistAndAlbumLabel: UILabel!
    @IBOutlet weak var totalPlaybackTImeLabel: UILabel!
    @IBOutlet weak var menuButton: UIView!
    
    override var alpha:CGFloat {
        didSet {
            albumArtImageView?.alpha = alpha
            songTitleLabel?.alpha = alpha
            albumArtistAndAlbumLabel?.alpha = alpha
            totalPlaybackTImeLabel?.alpha = alpha
            menuButton?.alpha = alpha
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureTextLabelsForMediaItem(mediaItem:MPMediaItem, isNowPlayingItem:Bool) {
        songTitleLabel.text = mediaItem.title
        albumArtistAndAlbumLabel.text = mediaItem.albumArtist + " - " + mediaItem.albumTitle
        totalPlaybackTImeLabel.text = MediaItemUtils.getTimeRepresentation(Float(mediaItem.playbackDuration))
        songTitleLabel.font = isNowPlayingItem ? SongDetailsTableViewCell.boldFont : SongDetailsTableViewCell.normalFont
        albumArtistAndAlbumLabel.font = isNowPlayingItem ? SongDetailsTableViewCell.boldFont : SongDetailsTableViewCell.normalFont

    }
    
}


