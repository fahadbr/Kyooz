//
//  AlbumTableViewCell.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/30/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class ImageTableViewCell: MediaLibraryTableViewCell{
    
	class var reuseIdentifier:String {
		return "imageTableViewCell"
	}
    
    private static let fadeInAnimation:CAAnimation = KyoozUtils.fadeInAnimationWithDuration(0.35)
    
    @IBOutlet weak var albumArtwork: UIImageView!
	
	private var shouldAnimate:Bool {
		return delegate?.shouldAnimateInArtwork ?? false
	}

    override func configureCellForItems(entity:AudioEntity, libraryGrouping:LibraryGrouping) {
        
        titleLabel.text = entity.titleForGrouping(libraryGrouping)
        
        let pluralText = entity.count > 1 ? "s" : ""
        var strings = [String]()
        
        let count = "\(entity.count) Track\(pluralText)"
		if let track = entity.representativeTrack {
			if libraryGrouping === LibraryGrouping.Albums || libraryGrouping === LibraryGrouping.Compilations {
                if let albumArtist = track.albumArtist {
                    strings.append(albumArtist)
                }
                strings.append(count)
				if let releaseDate = track.releaseYear {
					strings.append(releaseDate)
				}
			}
			configureDRMAndCloudLabels(track)
		} else {
			accessoryStack.hidden = true
		}
		
        detailsLabel.text = strings.isEmpty ? count : strings.joinWithSeparator(" • ")
        if shouldAnimate {
            albumArtwork.alpha = 0
		
            entity.artworkImage(forSize: albumArtwork.frame.size) { [albumArtwork = self.albumArtwork](image) in
                albumArtwork.alpha = 1
                albumArtwork.layer.addAnimation(ImageTableViewCell.fadeInAnimation, forKey: nil)
                albumArtwork.image = image
            }
        } else {
            albumArtwork.image = entity.artworkImage(forSize: albumArtwork.frame.size)
                ?? ImageUtils.resizeImage(ImageContainer.defaultAlbumArtworkImage, toSize: albumArtwork.frame.size)
        }
    }
    
}
