//
//  FilteredSongTableViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class AlbumTrackTableViewController: AbstractMediaEntityTableViewController {
    
    var albumCollection:MPMediaItemCollection!
    private var albumArt:UIImage?
    private var albumArtView:UIImageView?
    private var albumArtColor:UIColor?
    
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
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        guard let song = albumCollection.representativeItem else {
            Logger.debug("couldnt representitive item of songs array")
            return nil
        }
        cell.textLabel?.text = song.albumTitle
        cell.textLabel?.font = ThemeHelper.defaultFont
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.textLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        cell.textLabel?.numberOfLines = 2
        
        if(cell.imageView != nil) {
            albumArt = song.artwork?.imageWithSize(cell.imageView!.frame.size)
            let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Dark))
            blurView.frame = CGRect(origin: cell.frame.origin, size: CGSize(width: view.frame.width, height: 70))
            cell.insertSubview(blurView, atIndex: 0)
            if albumArt != nil {
                albumArtColor = UIColor(patternImage: albumArt!)
                cell.backgroundColor = albumArtColor
            }
        }
        cell.imageView?.image = albumArt
        
        return cell

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
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let index = indexPath.row
        let nowPlayingItem = albumCollection.items[index] as AudioTrack
        audioQueuePlayer.playNowWithCollection(mediaCollection: albumCollection,
            itemToPlay: nowPlayingItem)
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
