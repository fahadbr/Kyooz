//
//  SongTableViewCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/26/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class SongDetailsTableViewCell: AbstractTableViewCell, AudioTableCellProtocol {

    static let reuseIdentifier = "songDetailsTableViewCell"
    
    private static let normalFont = ThemeHelper.smallFontForStyle(.normal)
    private static let boldFont = ThemeHelper.smallFontForStyle(.medium)
    
    private static let albumImageCache = NSCache<NSNumber, UIImage>()
    
    
    @IBOutlet var albumArtImageView: UIImageView!
    @IBOutlet var songTitleLabel: UILabel!
    @IBOutlet var albumArtistAndAlbumLabel: UILabel!
    @IBOutlet var totalPlaybackTImeLabel: UILabel!
    @IBOutlet var menuButton:UIButton!
    
    weak var delegate:AudioTableCellDelegate?
    
    var isNowPlaying:Bool = false {
        didSet {
            if isNowPlaying != oldValue {
                songTitleLabel.textColor = isNowPlaying ? ThemeHelper.defaultVividColor : ThemeHelper.defaultFontColor
            }
        }
    }
    var shouldAnimate:Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        songTitleLabel.isAccessibilityElement = true
        songTitleLabel.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitAllowsDirectInteraction
        songTitleLabel.font = SongDetailsTableViewCell.boldFont
        albumArtistAndAlbumLabel.font =  SongDetailsTableViewCell.normalFont
        albumArtistAndAlbumLabel.textColor = UIColor.lightGray
    }
    
    @IBAction func menuButtonPressed(_ sender:UIButton!) {
        let point = CGPoint(x: bounds.maxX, y: bounds.midY)
//        let convertedPoint = convertPoint(point, fromCoordinateSpace: window!.screen.fixedCoordinateSpace)
        let convertedPoint = convert(point, to: ContainerViewController.instance.view)
        delegate?.presentActionsForCell(self, title: songTitleLabel.text, details: albumArtistAndAlbumLabel.text, originatingCenter: convertedPoint)
    }
    
    func configureCellForItems(_ entity:AudioEntity, libraryGrouping:LibraryGrouping) {
        guard let track = entity as? AudioTrack else { return }
        songTitleLabel.text = track.trackTitle
        songTitleLabel.accessibilityLabel = songTitleLabel.text
        var details = [String]()
        if let albumArtist = track.albumArtist {
            details.append(albumArtist)
        } else if let artist = track.artist {
            details.append(artist)
        }
        if let albumTitle = track.albumTitle {
            details.append(albumTitle)
        }
        
        albumArtistAndAlbumLabel.text = details.joined(separator: " - ")
        totalPlaybackTImeLabel.text = MediaItemUtils.getTimeRepresentation(track.playbackDuration)
        albumArtImageView.image = SongDetailsTableViewCell.getAlbumImageForTrack(track, imageSize: albumArtImageView.frame.size)
    }
    
    static func getAlbumImageForTrack(_ track:AudioTrack, imageSize:CGSize) -> UIImage {
        
        let key = NSNumber(value: track.albumId)
        if let albumArtImage = SongDetailsTableViewCell.albumImageCache.object(forKey: key) {
            return albumArtImage
        } else if let albumArtwork = track.artworkImage(forSize: imageSize) {
            SongDetailsTableViewCell.albumImageCache.setObject(albumArtwork, forKey: key)
            return albumArtwork
        }
        
        let defaultKey = -1
        guard let defaultAlbumArtImage = SongDetailsTableViewCell.albumImageCache.object(forKey: defaultKey) else {
            let noAlbumArtCellImage = ImageUtils.resizeImage(ImageContainer.smallDefaultArtworkImage, toSize: imageSize)
            SongDetailsTableViewCell.albumImageCache.setObject(noAlbumArtCellImage, forKey: defaultKey)
            return noAlbumArtCellImage
        }
        return defaultAlbumArtImage
        
    }

}


