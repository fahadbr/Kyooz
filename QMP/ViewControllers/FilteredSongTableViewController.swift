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
    
    let queueBasedMusicPlayer = MusicPlayerContainer.queueBasedMusicPlayer
    let musicPlayerTableViewActionFactory = MusicPlayerTableViewActionFactory.instance
    
    var songs:MPMediaItemCollection!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return songs.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("songCell", forIndexPath: indexPath) as! UITableViewCell

        let song = songs.items[indexPath.row] as! MPMediaItem
        cell.textLabel?.text = song.title
        cell.textLabel?.font = ThemeHelper.defaultFont
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        var index = indexPath.row
        var nowPlayingItem = songs.items[index] as! MPMediaItem
        queueBasedMusicPlayer.playNowWithCollection(mediaCollection: songs,
            itemToPlay: nowPlayingItem)
//        RootViewController.instance.animatePullablePanel(shouldExpand: true)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var song = self.songs.items[indexPath.row] as! MPMediaItem
        var enqueueAction = musicPlayerTableViewActionFactory.createEnqueueAction([song], tableViewDelegate: self, tableView: tableView, indexPath: indexPath)
        return [enqueueAction]
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source

        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        } else {
            var cell = tableView.cellForRowAtIndexPath(indexPath)
            cell?.endEditing(true)
        }
        
    }
    

    //MARK: Overriding QueableMediaItemTableViewController methods
    override func getMediaItemsForIndexPath(indexPath: NSIndexPath) -> [MPMediaItem] {
        if let items = songs.items as? [MPMediaItem] {
            let mediaItem = items[indexPath.row]
            return [mediaItem]
        }
        return [MPMediaItem]()
    }
    

}
