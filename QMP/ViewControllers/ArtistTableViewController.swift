//
//  ArtistTableViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/10/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class ArtistTableViewController: MediaItemTableViewController {
    
    let musicPlayerTableViewActionFactory = MusicPlayerTableViewActionFactory.instance
    
    var albumArtistsSections = [MPMediaQuerySection]()
    var albumArtists = [MPMediaItemCollection]()

    override func viewDidLoad() {
        super.viewDidLoad()
        let query = MPMediaQuery()
        query.groupingType = MPMediaGrouping.AlbumArtist
        query.addFilterPredicate(MPMediaPropertyPredicate(
            value: MPMediaType.Music.rawValue,
            forProperty: MPMediaItemPropertyMediaType))
        query.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
        
        let sectionResultSet = query.collectionSections
        if(sectionResultSet != nil) {
            albumArtistsSections = sectionResultSet! 
        }
        
        let resultSet = query.collections
        if(resultSet != nil){
            albumArtists = resultSet! 
        }
        
        tableView.registerClass(MediaCollectionTableViewCell.self, forCellReuseIdentifier: "artistCell")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return albumArtistsSections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumArtistsSections[section].range.length
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
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
        let cell = tableView.dequeueReusableCellWithIdentifier("artistCell", forIndexPath: indexPath) as! MediaCollectionTableViewCell
        let artist = albumArtists[getAbsoluteIndexForAlbumArtist(indexPath: indexPath)]
        cell.configureCellForItems(artist, collectionTitleProperty: MPMediaItemPropertyAlbumArtist)
        
        return cell
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return albumArtistsSections[section].title
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("albumArtistToAlbumSegue", sender: self)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier != nil && segue.identifier! == "albumArtistToAlbumSegue") {
            let vc = segue.destinationViewController as! FilteredAlbumTableViewController
            //var vc = nc.topViewController as FilteredAlbumTableViewController
            let indexPath = self.tableView.indexPathForSelectedRow
            if(indexPath != nil) {
                let artist = albumArtists[getAbsoluteIndexForAlbumArtist(indexPath: indexPath!)]
                let artistName = artist.representativeItem!.albumArtist
                let query = MPMediaQuery.albumsQuery()
                let filterPredicate = MPMediaPropertyPredicate(value: artistName, forProperty: MPMediaItemPropertyAlbumArtist, comparisonType: MPMediaPredicateComparison.EqualTo)
                query.addFilterPredicate(filterPredicate)
                
                if let resultSet = query.collections {
                    vc.albums = resultSet
                    vc.title = artistName
                }
                vc.tableView.reloadData()
            }
        }
    }
    
    private func getAbsoluteIndexForAlbumArtist(indexPath indexPath: NSIndexPath) -> Int{
        let offset =  albumArtistsSections[indexPath.section].range.location
        let index = indexPath.row
        let absoluteIndex = offset + index
        
        return absoluteIndex
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let albumSongs = self.albumArtists[getAbsoluteIndexForAlbumArtist(indexPath: indexPath)].items
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
        let absoluteIndex = getAbsoluteIndexForAlbumArtist(indexPath: indexPath)
        if absoluteIndex < albumArtists.count {
            return albumArtists[absoluteIndex].items
        }
        return [AudioTrack]()
    }


}
