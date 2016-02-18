//
//  CollectionDetailsHeaderViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/17/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class CollectionDetailsHeaderViewController : UIViewController, HeaderViewControllerProtocol {
    
    static var height:CGFloat = 375
    
    @IBOutlet var shuffleButton: ShuffleButtonView!
    @IBOutlet var selectModeButton: ListButtonView!
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var detailsLabel1: UILabel!
    @IBOutlet var detailsLabel2: UILabel!
    @IBOutlet var detailsLabel3: UILabel!
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var blurView: UIVisualEffectView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configureViewWithCollection(tracks:[AudioTrack]) {
        guard let track = tracks.first else {
            Logger.debug("couldnt get representative item for album collection")
            return
        }
        
        titleLabel.text = track.albumTitle
        
        
        detailsLabel1.text = track.albumArtist ?? track.artist
        
        var details = [String]()
        if let mediaItem = track as? MPMediaItem, let releaseDate = MediaItemUtils.getReleaseDateString(mediaItem) {
            details.append(releaseDate)
        }
        if let genre = track.genre {
            details.append(genre)
        }
        details.append("\(tracks.count) Tracks")
        
        detailsLabel3.text = details.joinWithSeparator(" • ")
        detailsLabel3.textColor = UIColor.lightGrayColor()
        
        if let albumArt = track.artwork {
            KyoozUtils.doInMainQueueAsync() { [weak self, albumImageView = self.imageView] in
                if let image = albumArt.imageWithSize(albumImageView.frame.size) {
                    albumImageView.image = image
                    albumImageView.layer.shadowOpacity = 0.6
                    albumImageView.layer.shadowOffset = CGSize(width: 0, height: 0)
                    self?.blurView.backgroundColor = UIColor(patternImage: image)
                }
            }
        } else {
            blurView.backgroundColor = ThemeHelper.darkAccentColor
        }
        
        KyoozUtils.doInMainQueueAsync() { [weak self] in
            self?.titleLabel.alpha = 0 //doing this here because for some reason it wont take effect when done synchronously with setting the navigation item
            
            var duration:NSTimeInterval = 0
            for item in tracks {
                duration += item.playbackDuration
            }
            if let albumDurationString = MediaItemUtils.getLongTimeRepresentation(duration) {
                self?.detailsLabel3.text = albumDurationString
                self?.detailsLabel3.textColor = UIColor.lightGrayColor()
            } else {
                self?.detailsLabel3.hidden = true
            }
        }
        
    }
    
    

}
