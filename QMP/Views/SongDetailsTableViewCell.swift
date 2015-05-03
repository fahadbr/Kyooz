//
//  SongTableViewCell.swift
//  QMP
//
//  Created by FAHAD RIAZ on 4/26/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

protocol SongDetailsTableViewCellDelegate:class {
    var menuButtonTouched:Bool { get set }
}

class SongDetailsTableViewCell: UITableViewCell {

    static let normalFont = UIFont(name:ThemeHelper.defaultFontName, size:12.0)
    static let boldFont = UIFont(name:ThemeHelper.defaultFontNameBold, size:12.0)
    
    @IBOutlet weak var albumArtImageView: UIImageView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var albumArtistAndAlbumLabel: UILabel!
    @IBOutlet weak var totalPlaybackTImeLabel: UILabel!
    @IBOutlet weak var menuButton: UIView!
    
    
    weak var delegate:SongDetailsTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "menuButtonPressed:")
        tapGestureRecognizer.cancelsTouchesInView = false
        self.menuButton.addGestureRecognizer(tapGestureRecognizer)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureTextLabelsForMediaItem(mediaItem:MPMediaItem, isNowPlayingItem:Bool) {
        songTitleLabel.text = mediaItem.title
        albumArtistAndAlbumLabel.text = mediaItem.albumArtist + " - " + mediaItem.albumTitle
        totalPlaybackTImeLabel.text = MediaItemUtils.getTimeRepresentation(Float(mediaItem.playbackDuration))
        songTitleLabel.font = isNowPlayingItem ? SongDetailsTableViewCell.boldFont : SongDetailsTableViewCell.normalFont
        albumArtistAndAlbumLabel.font = isNowPlayingItem ? SongDetailsTableViewCell.boldFont : SongDetailsTableViewCell.normalFont

    }
    
    
    func menuButtonPressed(sender: AnyObject) {
        println("menu button touched")
        delegate?.menuButtonTouched = true
    }
    
}


