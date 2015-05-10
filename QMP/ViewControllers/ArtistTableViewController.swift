//
//  ArtistTableViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/10/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class ArtistTableViewController: QueableMediaItemTableViewController {
    
    let musicPlayerTableViewActionFactory = MusicPlayerTableViewActionFactory.instance
    
    var albumArtistsSections = [MPMediaQuerySection]()
    var albumArtists = [MPMediaItemCollection]()

    override func viewDidLoad() {
        super.viewDidLoad()
        var query = MPMediaQuery()
        query.groupingType = MPMediaGrouping.AlbumArtist
        query.addFilterPredicate(MPMediaPropertyPredicate(
            value: MPMediaType.Music.rawValue,
            forProperty: MPMediaItemPropertyMediaType))
        
        var sectionResultSet = query.collectionSections
        if(sectionResultSet != nil) {
            albumArtistsSections = sectionResultSet! as! [MPMediaQuerySection]
        }
        
        var resultSet = query.collections
        if(resultSet != nil){
            albumArtists = resultSet! as! [MPMediaItemCollection]
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return albumArtistsSections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return albumArtistsSections[section].range.length
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        var titles = [String]()
        for artistSection in albumArtistsSections {
            titles.append(artistSection.title)
        }
        
        return titles
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return index
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("artistCell", forIndexPath: indexPath) as! UITableViewCell
        var artist = albumArtists[getAbsoluteIndexForAlbumArtist(indexPath: indexPath)]
        cell.textLabel?.text = artist.representativeItem.albumArtist
        cell.textLabel?.font = ThemeHelper.defaultFont

        return cell
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return albumArtistsSections[section].title
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier != nil && segue.identifier! == "albumArtistToAlbumSegue") {
            var vc = segue.destinationViewController as! FilteredAlbumTableViewController
            //var vc = nc.topViewController as FilteredAlbumTableViewController
            var indexPath = self.tableView.indexPathForSelectedRow()
            if(indexPath != nil) {
                var artist = albumArtists[getAbsoluteIndexForAlbumArtist(indexPath: indexPath!)]
                var artistName = artist.representativeItem.albumArtist
                var query = MPMediaQuery.albumsQuery()
                var filterPredicate = MPMediaPropertyPredicate(value: artistName, forProperty: MPMediaItemPropertyAlbumArtist, comparisonType: MPMediaPredicateComparison.EqualTo)
                query.addFilterPredicate(filterPredicate)
                
                var resultSet = query.collections
                if(resultSet != nil) {
                    vc.albums = resultSet as! [MPMediaItemCollection]
                    vc.title = artistName
                }
                vc.tableView.reloadData()
            }
        }
    }
    
    private func getAbsoluteIndexForAlbumArtist(#indexPath: NSIndexPath) -> Int{
        var offset =  albumArtistsSections[indexPath.section].range.location
        var index = indexPath.row
        var absoluteIndex = offset + index
        
        return absoluteIndex
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var albumSongs = self.albumArtists[getAbsoluteIndexForAlbumArtist(indexPath: indexPath)].items as! [MPMediaItem]
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

    
    //MARK: Overriding QueableMediaItemTableViewController methods
    override func getMediaItemsForIndexPath(indexPath: NSIndexPath) -> [MPMediaItem] {
        if let items = albumArtists[getAbsoluteIndexForAlbumArtist(indexPath: indexPath)].items as? [MPMediaItem] {
            return items
        }
        return [MPMediaItem]()
    }


}
