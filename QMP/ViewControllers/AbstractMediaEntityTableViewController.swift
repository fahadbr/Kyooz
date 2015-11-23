//
//  AbstractMediaEntityTableViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 10/5/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

class AbstractMediaEntityTableViewController : AbstractTableViewController, MediaItemTableViewControllerProtocol {
    
    private static let greenColor = UIColor(red: 95.0/225.0, green: 118.0/225.0, blue: 97.0/225.0, alpha: 1)
    private static let blueColor = UIColor(red: 95.0/225.0, green: 110.0/225.0, blue: 118.0/225.0, alpha: 1)
    
    let fatalErrorMessage = "Unsupported operation. this is an abstract class"
    let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    var libraryGroupingType:LibraryGrouping!
    var filterQuery:MPMediaQuery!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadSourceData()
        registerForNotifications()
    }
    
    
    deinit {
        unregisterForNotifications()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let mediaItems = getMediaItemsForIndexPath(indexPath)
        
        let playLastAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Play\nLast",
                handler: {action, index in
                    self.audioQueuePlayer.enqueue(mediaItems)
                    self.tableView(tableView, didEndEditingRowAtIndexPath: indexPath)
            })
        let playNextAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Play\nNext",
            handler: {action, index in
                self.audioQueuePlayer.insertItemsAtIndex(mediaItems, index: self.audioQueuePlayer.indexOfNowPlayingItem + 1)
                self.tableView(tableView, didEndEditingRowAtIndexPath: indexPath)
        })
        
        playLastAction.backgroundColor = AbstractMediaEntityTableViewController.blueColor
        playNextAction.backgroundColor = AbstractMediaEntityTableViewController.greenColor

        
        return [playLastAction, playNextAction]
    }

    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    //MARK: - Class functions
    func reloadAllData() {
        Logger.debug("Reloading all media entity data")
        reloadSourceData()
        reloadTableViewData()
    }
    
    func reloadTableViewData() {
        tableView.reloadData()
    }
    
    func reloadSourceData() {
        fatalError(fatalErrorMessage)
    }
    
    //MARK: - Overriding MediaItemTableViewController methods
    func getMediaItemsForIndexPath(indexPath: NSIndexPath) -> [AudioTrack] {
        fatalError(fatalErrorMessage)
    }
    
    //MARK: - Private functions
    
    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "reloadTableViewData",
            name: AudioQueuePlayerUpdate.NowPlayingItemChanged.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadTableViewData",
            name: AudioQueuePlayerUpdate.PlaybackStateUpdate.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadAllData",
            name: MPMediaLibraryDidChangeNotification, object: MPMediaLibrary.defaultMediaLibrary())
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
}
