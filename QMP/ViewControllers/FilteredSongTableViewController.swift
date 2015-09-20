//
//  FilteredSongTableViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class FilteredSongTableViewController: MediaItemTableViewController {
    
    let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    let musicPlayerTableViewActionFactory = MusicPlayerTableViewActionFactory.instance
    
    var songs:MPMediaItemCollection!
    var albumArt:UIImage?
    var albumArtView:UIImageView?
    var albumArtColor:UIColor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForNotifications()
        self.tableView.registerNib(NibContainer.albumTrackTableViewCellNib, forCellReuseIdentifier: AlbumTrackTableViewCell.reuseIdentifier)
    }
    
    deinit {
        unregisterForNotifications()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
        guard let song = songs.representativeItem else {
            Logger.debug("couldnt representitive item of songs array")
            return nil
        }
        cell.textLabel?.text = song.albumTitle
        cell.textLabel?.font = ThemeHelper.defaultFont
        cell.textLabel?.textColor = UIColor.whiteColor()
//        cell.textLabel?.textAlignment = NSTextAlignment.Center
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

        let track = songs.items[indexPath.row] as AudioTrack
        cell.configureCellForItem(track)
        
        if let currentTrack = audioQueuePlayer.nowPlayingItem {
            cell.isNowPlayingItem = (currentTrack.id == track.id)
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let index = indexPath.row
        let nowPlayingItem = songs.items[index] as AudioTrack
        audioQueuePlayer.playNowWithCollection(mediaCollection: songs,
            itemToPlay: nowPlayingItem)
//        RootViewController.instance.animatePullablePanel(shouldExpand: true)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let song = self.songs.items[indexPath.row] as AudioTrack
        let enqueueAction = musicPlayerTableViewActionFactory.createEnqueueAction([song], tableViewDelegate: self, tableView: tableView, indexPath: indexPath)
        return [enqueueAction]
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source

        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        } else {
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            cell?.endEditing(true)
        }
        
    }
    

    //MARK: Overriding QueableMediaItemTableViewController methods
    override func getMediaItemsForIndexPath(indexPath: NSIndexPath) -> [AudioTrack] {
        if songs.count > 0 {
            let mediaItem = songs.items[indexPath.row]
            return [mediaItem]
        }
        return [AudioTrack]()
    }
    
    func reloadTableData(notification:NSNotification?) {
        tableView.reloadData()
    }
    
    
    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "reloadTableData:",
            name: AudioQueuePlayerUpdate.NowPlayingItemChanged.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadTableData:",
            name: AudioQueuePlayerUpdate.PlaybackStateUpdate.rawValue, object: audioQueuePlayer)
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}
