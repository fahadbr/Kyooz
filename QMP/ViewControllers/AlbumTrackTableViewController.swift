//
//  FilteredSongTableViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

private let alphaKey = "alpha"

final class AlbumTrackTableViewController: ParentMediaEntityHeaderViewController {
    
    @IBOutlet var albumImageView: UIImageView!
    
    @IBOutlet var albumTitleLabel: UILabel!
    @IBOutlet var albumArtistLabel: UILabel!
    @IBOutlet var albumDurationLabel: UILabel!
    @IBOutlet var albumDetailsLabel: UILabel!
    
    @IBOutlet var blurView: UIVisualEffectView!
    
    
    private var titleLabel:UILabel!
    
    private var kvoContext:NSNumber = NSNumber(char: 10)
    private var observingHeaderView = false
	
    
    deinit {
        if observingHeaderView {
            headerView.removeObserver(self, forKeyPath: alphaKey)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(NibContainer.albumTrackTableViewCellNib, forCellReuseIdentifier: AlbumTrackTableViewCell.reuseIdentifier)
        
        guard let track = sourceData.entities.first?.representativeTrack else {
            Logger.debug("couldnt get representative item for album collection")
            return
        }
        
        albumTitleLabel.text = track.albumTitle
        
        titleLabel = UILabel()
        titleLabel.text = track.albumTitle?.uppercaseString
        titleLabel.font = UIFont(name: ThemeHelper.defaultFontNameBold, size: ThemeHelper.defaultFontSize)
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.textAlignment = .Center
        titleLabel.sizeToFit()
        titleLabel.hidden = true
        navigationItem.titleView = titleLabel
        
        albumArtistLabel.text = track.albumArtist ?? track.artist
        
        var details = [String]()
        if let mediaItem = track as? MPMediaItem, let releaseDate = MediaItemUtils.getReleaseDateString(mediaItem) {
            details.append(releaseDate)
        }
        if let genre = track.genre {
            details.append(genre)
        }
        details.append("\(sourceData.entities.count) Tracks")
        
        albumDetailsLabel.text = details.joinWithSeparator(" • ")
        albumDetailsLabel.textColor = UIColor.lightGrayColor()
        
        if let albumArt = track.artwork {
            KyoozUtils.doInMainQueueAsync() { [weak self, albumImageView = self.albumImageView] in
                if let image = albumArt.imageWithSize(albumImageView.frame.size) {
                    albumImageView.image = image
                    albumImageView.layer.shadowOpacity = 0.6
                    albumImageView.layer.shadowOffset = CGSize(width: 0, height: 0)
                    self?.blurView.backgroundColor = UIColor(patternImage: image)
                }
            }
        } else {
            albumImageView.hidden = true
            blurView.backgroundColor = UIColor.blackColor()
        }
        
        KyoozUtils.doInMainQueueAsync() { [weak self] in
            self?.titleLabel.alpha = 0 //doing this here because for some reason it wont take effect when done synchronously with setting the navigation item
            
            if let items = self?.sourceData.entities as? [AudioTrack] {
                var duration:NSTimeInterval = 0
                for item in items {
                    duration += item.playbackDuration
                }
                if let albumDurationString = MediaItemUtils.getLongTimeRepresentation(duration) {
                    self?.albumDurationLabel.text = albumDurationString
                    self?.albumDurationLabel.textColor = UIColor.lightGrayColor()
                } else {
                    self?.albumDurationLabel.hidden = true
                }
            }
        }
        
        headerView.addObserver(self, forKeyPath: alphaKey, options: .New, context: &kvoContext)
        observingHeaderView = true
    }
    
    
    override func applyDataSourceAndDelegate() {
        guard !tableView.editing else {
            return
        }
        datasourceDelegate = AudioTrackDSD(sourceData:sourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: self)
    }
    

    //MARK: - Overriding MediaItemTableViewController methods
    override func getMediaItemsForIndexPath(indexPath: NSIndexPath) -> [AudioTrack] {
        return sourceData.getTracksAtIndex(indexPath)
    }
    

    
    //MARK: KVO
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath != nil && keyPath! == alphaKey {
            let alpha = headerView.alpha
            if alpha <= 0.25 {
                titleLabel.hidden = false
                let percentage = alpha * 4
                titleLabel.alpha = 1 - percentage
            } else {
                titleLabel.alpha = 0
                titleLabel.hidden = true
            }
        }
    }

}
