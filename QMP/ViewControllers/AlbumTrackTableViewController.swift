//
//  FilteredSongTableViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class AlbumTrackTableViewController: ParentMediaEntityHeaderViewController {
    
    var albumCollection:MPMediaItemCollection!
    
    @IBOutlet var albumImageView: UIImageView!
    
    @IBOutlet var albumTitleLabel: UILabel!
    @IBOutlet var albumArtistLabel: UILabel!
    @IBOutlet var albumDurationLabel: UILabel!
    @IBOutlet var albumDetailsLabel: UILabel!
    
    @IBOutlet var blurView: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(NibContainer.albumTrackTableViewCellNib, forCellReuseIdentifier: AlbumTrackTableViewCell.reuseIdentifier)
        
        guard let track = albumCollection.representativeItem else {
            Logger.debug("couldnt get representative item for album collection")
            return
        }
        
        albumTitleLabel.text = track.albumTitle
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
        
        if let albumArt = track.artwork {
            KyoozUtils.doInMainQueueAsync() { [weak self, albumImageView = self.albumImageView] in
                if let image = albumArt.imageWithSize(albumImageView.frame.size) {
                    albumImageView.image = image
                    self?.blurView.backgroundColor = UIColor(patternImage: image)
                    self?.headerView.layer.shouldRasterize = true
                    self?.headerView.layer.rasterizationScale = UIScreen.mainScreen().scale
                }
            }
        } else {
            albumImageView.hidden = true
        }
        
        KyoozUtils.doInMainQueueAsync() { [weak self] in
            if let items = self?.albumCollection?.items {
                var duration:NSTimeInterval = 0
                for item in items {
                    duration += item.playbackDuration
                }
                if let albumDurationString = MediaItemUtils.getLongTimeRepresentation(duration) {
                    self?.albumDurationLabel.text = albumDurationString
                } else {
                    self?.albumDurationLabel.hidden = true
                }
            }
            
        }
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

}
