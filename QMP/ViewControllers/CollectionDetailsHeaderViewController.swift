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
    
    @IBOutlet var headerTitleLabel: UILabel!
    
    @IBOutlet var detailsLabel1: UILabel!
    @IBOutlet var detailsLabel2: UILabel!
    @IBOutlet var detailsLabel3: UILabel!
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var blurView: UIVisualEffectView!
    
	let gradiant:CAGradientLayer = {
		let gradiant = CAGradientLayer()
		gradiant.startPoint = CGPoint(x: 0.5, y: 1.0)
		gradiant.endPoint = CGPoint(x: 0.5, y: 0.75)
		gradiant.colors = [UIColor.blackColor().CGColor, UIColor.clearColor().CGColor]
		return gradiant
	}()
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configureViewWithCollection(tracks:[AudioTrack]) {
        guard let track = tracks.first else {
            Logger.debug("couldnt get representative item for album collection")
            return
        }
		
		gradiant.frame = imageView.bounds
		imageView.layer.addSublayer(gradiant)
        
        headerTitleLabel.text = track.albumTitle?.uppercaseString
        
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
            
            var duration:NSTimeInterval = 0
            for item in tracks {
                duration += item.playbackDuration
            }
            if let albumDurationString = MediaItemUtils.getLongTimeRepresentation(duration) {
                self?.detailsLabel2.text = albumDurationString
                self?.detailsLabel2.textColor = UIColor.lightGrayColor()
            } else {
                self?.detailsLabel2.hidden = true
            }
        }
        
    }
    
    

}
