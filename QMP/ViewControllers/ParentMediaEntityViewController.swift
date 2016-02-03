//
//  ParentMediaEntityViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/3/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class ParentMediaEntityViewController : CustomPopableViewController, MediaItemTableViewControllerProtocol, ConfigurableAudioTableCellDelegate {
    private static let greenColor = UIColor(red: 0.0/225.0, green: 184.0/225.0, blue: 24.0/225.0, alpha: 1)
    private static let blueColor = UIColor(red: 51.0/225.0, green: 62.0/225.0, blue: 222.0/225.0, alpha: 1)
    
    let fatalErrorMessage = "Unsupported operation. this is an abstract class"
    let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    @IBOutlet var tableView:UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        tableView.rowHeight = 60
        tableView.allowsMultipleSelectionDuringEditing = true
        reloadSourceData()
        registerForNotifications()
    }
    
    deinit {
        unregisterForNotifications()
        Logger.debug("deinitializing media entity vc")
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
    
    //MARK: - MediaLibraryTableViewCellDelegate
    func presentActionsForIndexPath(indexPath:NSIndexPath, title:String?, details:String?) {
        let mediaItems = getMediaItemsForIndexPath(indexPath)
        ContainerViewController.instance.presentActionsForTracks(mediaItems, title: title, details: details)
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
