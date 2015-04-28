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
    func presentMenuItems(sender:SongDetailsTableViewCell)
}

class SongDetailsTableViewCell: UITableViewCell {

    @IBOutlet weak var albumArtImageView: UIImageView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var albumArtistAndAlbumLabel: UILabel!
    @IBOutlet weak var totalPlaybackTImeLabel: UILabel!
    @IBOutlet weak var menuButton: UIView!
    
    weak var delegate:SongDetailsTableViewCellDelegate?
    
    var indexInQueue:Int!
    
    var menuButtonTouched:Bool = false
    
    var currentlyPlaying:Bool = false {
        didSet {
            if(currentlyPlaying) {
                self.albumArtImageView.image = ImageContainer.currentlyPlayingImage
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "menuButtonPressed:")
        tapGestureRecognizer.cancelsTouchesInView = false
        self.menuButton.addGestureRecognizer(tapGestureRecognizer)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureForMediaItem(mediaItem:MPMediaItem) {
        let albumArtwork = mediaItem.artwork?.imageWithSize(self.albumArtImageView.frame.size)
        if(albumArtwork == nil) {
            self.albumArtImageView.image = ImageContainer.defaultAlbumArtworkImage
        } else {
            self.albumArtImageView.image = albumArtwork
        }
        self.songTitleLabel.text = mediaItem.title
        self.albumArtistAndAlbumLabel.text = mediaItem.albumArtist + " - " + mediaItem.albumTitle
        self.totalPlaybackTImeLabel.text = MediaItemUtils.getTimeRepresentation(mediaItem.playbackDuration)
        
    }
    
    
    func menuButtonPressed(sender: AnyObject) {
        println("menu button touched")
        self.menuButtonTouched = true
    }
    
    func getMenuButtonTouched() -> Bool {
        let originalValue = self.menuButtonTouched
        self.menuButtonTouched = false
        println("resetting menu button touched")
        return originalValue
    }
    
    
}


