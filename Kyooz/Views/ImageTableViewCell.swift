//
//  AlbumTableViewCell.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/30/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class ImageTableViewCell: MediaLibraryTableViewCell, ConfigurableAudioTableCell{
    
	class var reuseIdentifier:String {
		return "imageTableViewCell"
	}
    
    private static let fadeInAnimation:CAAnimation = KyoozUtils.fadeInAnimationWithDuration(0.35)
    
    @IBOutlet weak var albumArtwork: UIImageView!
    
    private var currentAlbumImageID:UInt64? = nil

    final func configureCellForItems(entity:AudioEntity, libraryGrouping:LibraryGrouping) {
        
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
        }
        KyoozUtils.doInMainQueueAsync() { [albumArtwork = self.albumArtwork] in
            albumArtwork.alpha = 1
            let track = entity.representativeTrack
            let albumId = track?.albumId ?? 0
            guard albumId != self.currentAlbumImageID else { return }
            
            if self.shouldAnimate {
                albumArtwork.layer.addAnimation(ImageTableViewCell.fadeInAnimation, forKey: nil)
            }
            guard let albumArtworkTemp = track?.artwork?.imageWithSize(albumArtwork.frame.size) else {
                albumArtwork.image = ImageContainer.resizeImage(ImageContainer.smallDefaultArtworkImage, toSize: albumArtwork.frame.size)
                self.currentAlbumImageID = 0
                return
            }
            albumArtwork.image = albumArtworkTemp
        }
    
    }
    
}
