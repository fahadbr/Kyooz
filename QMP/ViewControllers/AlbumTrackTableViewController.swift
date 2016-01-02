//
//  FilteredSongTableViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class AlbumTrackTableViewController: AbstractMediaEntityTableViewController {
    
    var albumCollection:MPMediaItemCollection!
    
    override var headerHeight:CGFloat {
        return 115
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(NibContainer.albumTrackTableViewCellNib, forCellReuseIdentifier: AlbumTrackTableViewCell.reuseIdentifier)
    }
    

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumCollection.count
    }
    
    
    override func getViewForHeader() -> UIView? {
        guard let albumHeaderView = NSBundle.mainBundle().loadNibNamed("AlbumHeaderView", owner: self, options: nil)?.first as? AlbumHeaderView else {
            return nil
        }
        guard let track = albumCollection.representativeItem else {
            Logger.debug("couldnt get representative item for album collection")
            return nil
        }
        
        albumHeaderView.albumTitleLabel.text = track.albumTitle
        albumHeaderView.albumArtistLabel.text = track.albumArtist ?? track.artist
        
        var details = [String]()
        if let releaseDate = MediaItemUtils.getReleaseDateString(track) {
            details.append(releaseDate)
        }
        if let genre = track.genre {
            details.append(genre)
        }
        details.append("\(albumCollection.count) Tracks")
        
        albumHeaderView.albumDetailsLabel.text = details.joinWithSeparator(" • ")
        
        if let albumArt = track.artwork {
            KyoozUtils.doInMainQueueAsync() {
                if let image = albumArt.imageWithSize(albumHeaderView.albumImage.frame.size) {
                    albumHeaderView.albumImage.image = image
                    albumHeaderView.backgroundColor = UIColor(patternImage: image)
                }
            }
        } else {
            albumHeaderView.albumImage.hidden = true
        }
        
        KyoozUtils.doInMainQueueAsync() { [weak albumCollection = self.albumCollection] in
            if let items = albumCollection?.items {
                var duration:NSTimeInterval = 0
                for item in items {
                    duration += item.playbackDuration
                }
                if let albumDurationString = MediaItemUtils.getLongTimeRepresentation(duration) {
                    albumHeaderView.albumDurationLabel.text = albumDurationString
                } else {
                    albumHeaderView.albumDurationLabel.hidden = true
                }
            }
            
        }
        return albumHeaderView
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
        audioQueuePlayer.playNow(withTracks: albumCollection.items, startingAtIndex: indexPath.row)
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
