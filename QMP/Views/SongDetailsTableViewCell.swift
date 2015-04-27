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
    @IBOutlet weak var menuButton: UIButton!
    
    weak var delegate:SongDetailsTableViewCellDelegate?
    
    var indexInQueue:Int!
    
    var currentlyPlaying:Bool = false {
        didSet {
            if(currentlyPlaying) {
                self.albumArtImageView.image = ImageContainer.currentlyPlayingImage
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        println("loading SongTableViewCell from nib")
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
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
    
    @IBAction func menuButtonPressed(sender: AnyObject) {
        delegate?.presentMenuItems(self)
    }
    
    
}
