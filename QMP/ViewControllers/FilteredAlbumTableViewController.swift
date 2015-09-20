//
//  FilteredAlbumTableViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//


import MediaPlayer

class FilteredAlbumTableViewController: MediaItemTableViewController {

    let musicPlayerTableViewActionFactory = MusicPlayerTableViewActionFactory.instance
    let cellTableIdentifier = "albumTableViewCell"
    let albumToSongSegueIdentifier = "albumToSongSegue"
    var albums = [MPMediaItemCollection]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(NibContainer.albumTableViewCellNib, forCellReuseIdentifier: cellTableIdentifier)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellTableIdentifier, forIndexPath: indexPath) as! AlbumTableViewCell
        let album = albums[indexPath.row]
        cell.configureCellForItems(album, collectionTitleProperty: MPMediaItemPropertyAlbumTitle)
        
        return cell
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier != nil && segue.identifier! == albumToSongSegueIdentifier) {
            let vc = segue.destinationViewController as! FilteredSongTableViewController
            //var vc = nc.topViewController as FilteredAlbumTableViewController
            let indexPath = self.tableView.indexPathForSelectedRow
            if(indexPath != nil) {
                let indexPathUnwrapped = indexPath!
                let album = albums[indexPathUnwrapped.row]
                vc.songs = album
                vc.tableView.reloadData()
            }
        }

    }
    

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier(albumToSongSegueIdentifier, sender: self)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let albumSongs = albums[indexPath.row].items
        let enqueueAction = musicPlayerTableViewActionFactory.createEnqueueAction(albumSongs, tableViewDelegate: self, tableView: tableView, indexPath: indexPath)
        return [enqueueAction]
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    //MARK: Overriding QueableMediaItemTableViewController methods
    override func getMediaItemsForIndexPath(indexPath: NSIndexPath) -> [AudioTrack] {
        if indexPath.row < albums.count {
            return albums[indexPath.row].items
        }
        return [AudioTrack]()
    }
    
  
}
