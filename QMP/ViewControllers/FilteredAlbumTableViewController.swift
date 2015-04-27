//
//  FilteredAlbumTableViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//


import MediaPlayer

class FilteredAlbumTableViewController: UITableViewController {

    let musicPlayerTableViewActionFactory = MusicPlayerTableViewActionFactory.instance
    let cellTableIdentifier = "albumTableViewCell"
    let albumToSongSegueIdentifier = "albumToSongSegue"
    var albums = [MPMediaItemCollection]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(NibContainer.albumTableViewCellNib, forCellReuseIdentifier: cellTableIdentifier)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        albums.removeAll(keepCapacity: false)
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
        return albums.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellTableIdentifier, forIndexPath: indexPath) as! AlbumTableViewCell
        var album = albums[indexPath.row]
        cell.albumTitle.text = album.representativeItem.albumTitle
        cell.albumDetails.text = "\(album.count) Tracks"
        let albumArtwork = album.representativeItem?.artwork?.imageWithSize(cell.albumArtwork.frame.size)
        if(albumArtwork == nil) {
            cell.albumArtwork?.image = ImageContainer.defaultAlbumArtworkImage
        } else {
            cell.albumArtwork?.image = albumArtwork
        }
        return cell
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier != nil && segue.identifier! == albumToSongSegueIdentifier) {
            var vc = segue.destinationViewController as! FilteredSongTableViewController
            //var vc = nc.topViewController as FilteredAlbumTableViewController
            var indexPath = self.tableView.indexPathForSelectedRow()
            if(indexPath != nil) {
                var indexPathUnwrapped = indexPath!
                var album = albums[indexPathUnwrapped.row]
                var albumName = album.representativeItem.albumTitle
                vc.songs = album
                vc.title = albumName
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
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var albumSongs = self.albums[indexPath.row].items as! [MPMediaItem]
        var enqueueAction = musicPlayerTableViewActionFactory.createEnqueueAction(albumSongs, tableViewDelegate: self, tableView: tableView, indexPath: indexPath)
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
    
    @IBAction func unwindToBrowser(segue : UIStoryboardSegue)  {
        
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation
*/

}