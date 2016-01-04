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
    
    var albumCollection:MPMediaItemCollection!
    
    @IBOutlet var albumImageView: UIImageView!
    
    @IBOutlet var albumTitleLabel: UILabel!
    @IBOutlet var albumArtistLabel: UILabel!
    @IBOutlet var albumDurationLabel: UILabel!
    @IBOutlet var albumDetailsLabel: UILabel!
    
    @IBOutlet var blurView: UIVisualEffectView!
    
    @IBOutlet var subStackViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet var subStackViewHeightConstraint: NSLayoutConstraint!
    private var _headerHeight:CGFloat!
    private var subStackViewLeftConstraintConstant:CGFloat!
    
    override var headerHeight:CGFloat {
        return _headerHeight
    }
    
    private var titleLabel:UILabel!
    
    private var kvoContext:NSNumber = NSNumber(char: 10)
    
    deinit {
        headerView.removeObserver(self, forKeyPath: alphaKey)
    }
    
    override func viewDidLoad() {
        _headerHeight = headerHeightConstraint.constant - subStackViewHeightConstraint.constant
        subStackViewLeftConstraintConstant = subStackViewLeftConstraint.constant
        super.viewDidLoad()
        self.tableView.registerNib(NibContainer.albumTrackTableViewCellNib, forCellReuseIdentifier: AlbumTrackTableViewCell.reuseIdentifier)
        
        guard let track = albumCollection.representativeItem else {
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
        navigationItem.titleView = titleLabel
        
        albumArtistLabel.text = track.albumArtist ?? track.artist
        
        var details = [String]()
        if let releaseDate = MediaItemUtils.getReleaseDateString(track) {
            details.append(releaseDate)
        }
        if let genre = track.genre {
            details.append(genre)
        }
        details.append("\(albumCollection.count) Tracks")
        
        albumDetailsLabel.text = details.joinWithSeparator(" • ")
        albumDetailsLabel.textColor = UIColor.lightGrayColor()
        
        if let albumArt = track.artwork {
            KyoozUtils.doInMainQueueAsync() { [weak self, albumImageView = self.albumImageView] in
                if let image = albumArt.imageWithSize(albumImageView.frame.size) {
                    albumImageView.image = image
                    self?.blurView.backgroundColor = UIColor(patternImage: image)
                }
            }
        } else {
            albumImageView.hidden = true
            subStackViewLeftConstraintConstant = 0
            subStackViewLeftConstraint.constant = 0
            blurView.backgroundColor = UIColor.blackColor()
        }
        
        KyoozUtils.doInMainQueueAsync() { [weak self] in
            self?.titleLabel.alpha = 0 //doing this here because for some reason it wont take effect when done synchronously with setting the navigation item
            
            if let items = self?.albumCollection?.items {
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
    }
    

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumCollection.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(AlbumTrackTableViewCell.reuseIdentifier, forIndexPath: indexPath) as! AlbumTrackTableViewCell

        let track = albumCollection.items[indexPath.row] as AudioTrack
        cell.configureCellForItem(track)
        
        if let currentTrack = audioQueuePlayer.nowPlayingItem {
            cell.isNowPlayingItem = (currentTrack.id == track.id)
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing {
            super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
            return
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        audioQueuePlayer.playNow(withTracks: albumCollection.items, startingAtIndex: indexPath.row, completionBlock: nil)
    }
    

    //MARK: - Overriding MediaItemTableViewController methods
    override func getMediaItemsForIndexPath(indexPath: NSIndexPath) -> [AudioTrack] {
        if albumCollection.count > 0 {
            let mediaItem = albumCollection.items[indexPath.row]
            return [mediaItem]
        }
        return [AudioTrack]()
    }
    
    
    override func reloadSourceData() {
        if let mediaItems = filterQuery.items {
            albumCollection = MPMediaItemCollection(items: mediaItems)
        } else {
            Logger.error("Could not find items for query \(filterQuery.description)")
        }
    }
    
    //MARK: KVO
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath != nil && keyPath! == alphaKey {
            let alpha = headerView.alpha
            if alpha <= 0.25 {
                let percentage = alpha * 4
                titleLabel.alpha = 1 - percentage
//                subStackViewLeftConstraint.constant = percentage * subStackViewLeftConstraintConstant
            } else {
                titleLabel.alpha = 0
//                subStackViewLeftConstraint.constant = subStackViewLeftConstraintConstant
            }
            subStackViewLeftConstraint.constant = alpha * subStackViewLeftConstraintConstant
        }
    }

}
