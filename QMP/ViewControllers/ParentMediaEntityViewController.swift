//
//  ParentMediaEntityViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/3/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

class ParentMediaEntityViewController : UIViewController, MediaItemTableViewControllerProtocol {
    private static let greenColor = UIColor(red: 0.0/225.0, green: 184.0/225.0, blue: 24.0/225.0, alpha: 1)
    private static let blueColor = UIColor(red: 51.0/225.0, green: 62.0/225.0, blue: 222.0/225.0, alpha: 1)
    
    let fatalErrorMessage = "Unsupported operation. this is an abstract class"
    let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    @IBOutlet var tableView:UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = 60
        tableView.allowsMultipleSelectionDuringEditing = true
        reloadSourceData()
        registerForNotifications()
    }
    
    deinit {
        unregisterForNotifications()
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let mediaItems = getMediaItemsForIndexPath(indexPath)
        var actions = [UITableViewRowAction]()
        
        
        let playLastAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Queue\nLast",
            handler: {action, index in
                self.audioQueuePlayer.enqueue(items: mediaItems, atPosition: .Last)
                self.tableView.editing = false
        })
        actions.append(playLastAction)
        let playNextAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Queue\nNext",
            handler: {action, index in
                self.audioQueuePlayer.enqueue(items: mediaItems, atPosition: .Next)
                self.tableView.editing = false
        })
        actions.append(playNextAction)
        
        if audioQueuePlayer.shuffleActive {
            let playRandomlyAction = UITableViewRowAction(style: .Normal, title: "Queue\nRandomly", handler: { (action, index) -> Void in
                self.audioQueuePlayer.enqueue(items: mediaItems, atPosition: .Random)
                self.tableView.editing = false
            })
            actions.append(playRandomlyAction)
        }
        
        
        playLastAction.backgroundColor = ParentMediaEntityViewController.blueColor
        playNextAction.backgroundColor = ParentMediaEntityViewController.greenColor
        
        
        return actions
    }
    

    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
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
