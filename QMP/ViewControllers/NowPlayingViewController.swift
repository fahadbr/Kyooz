//
//  NowPlayingViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class NowPlayingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SongDetailsTableViewCellDelegate  {

    let notificationCenter = NSNotificationCenter.defaultCenter()
    let queueBasedMusicPlayer = MusicPlayerContainer.queueBasedMusicPlayer
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.defaultCenter()
    
    var menuButtonTouched:Bool = false
    var viewExpanded:Bool = false {
        didSet {
            reloadTableData(nil)
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(NibContainer.songTableViewCellNib, forCellReuseIdentifier: "songDetailsTableViewCell")
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        registerForNotifications()
    }
    
    deinit {
        unregisterForNotifications()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let nowPlayingQueue = queueBasedMusicPlayer.getNowPlayingQueue()
        if(nowPlayingQueue != nil) {
            var count = nowPlayingQueue!.count
            return count
        } else {
            return 0
        }
    }

    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("songDetailsTableViewCell", forIndexPath: indexPath) as! SongDetailsTableViewCell
        
        var queue = queueBasedMusicPlayer.getNowPlayingQueue()
        if(queue == nil) {
            return cell
        }
        
        var wrappedSong = queue?[indexPath.row]
        if(wrappedSong == nil) {
            return cell
        }
        
        var song = wrappedSong!
        
        cell.configureForMediaItem(song)
        cell.delegate = self
        cell.currentlyPlaying = false
        
        if(queueBasedMusicPlayer.musicIsPlaying && isNowPlayingItem(mediaItemToCompare:song)) {
            cell.currentlyPlaying = true
        }

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(menuButtonTouched) {
            presentMenuItems(forIndex: indexPath.row)
            menuButtonTouched = false
        } else {
            queueBasedMusicPlayer.playItemWithIndexInCurrentQueue(index: indexPath.row)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    

    
    private func getSongForIndex(index: Int) -> MPMediaItem? {
        var queue = queueBasedMusicPlayer.getNowPlayingQueue()
        if(queue == nil) {
            return nil
        }
        
        return queue?[index]
    }
    
    private func isNowPlayingItem(#mediaItemToCompare:MPMediaItem) -> Bool{
        if let nowPlayingItem = self.queueBasedMusicPlayer.nowPlayingItem {
            return nowPlayingItem.persistentID == mediaItemToCompare.persistentID
        } else {
            return false
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        return indexPath.row == queueBasedMusicPlayer.indexOfNowPlayingItem ? .None : .Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            queueBasedMusicPlayer.deleteItemAtIndexFromQueue(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
           
        }
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        queueBasedMusicPlayer.moveMediaItem(fromIndexPath:sourceIndexPath.row, toIndexPath: destinationIndexPath.row)
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func reloadTableData(notification:NSNotification?) {
        if(viewExpanded) {
            println("reloading now playing queue table view")
            tableView.reloadData()
        }
    }
    
    
    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let application = UIApplication.sharedApplication()
        notificationCenter.addObserver(self, selector: "reloadTableData:",
            name: QueueBasedMusicPlayerUpdate.NowPlayingItemChanged.rawValue, object: queueBasedMusicPlayer)
        notificationCenter.addObserver(self, selector: "reloadTableData:",
            name: QueueBasedMusicPlayerUpdate.PlaybackStateUpdate.rawValue, object: queueBasedMusicPlayer)
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    
    private func presentMenuItems(forIndex index:Int) {
        let mediaItem = queueBasedMusicPlayer.getNowPlayingQueue()![index]
        let controller = UIAlertController(title: mediaItem.title + "\n" + mediaItem.albumArtist + " - " + mediaItem.albumTitle, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        controller.addAction(cancelAction)
        
        let indexOfNowPlayingItem = queueBasedMusicPlayer.indexOfNowPlayingItem
        
        if(!queueBasedMusicPlayer.musicIsPlaying || index >= indexOfNowPlayingItem) {
            let clearUpcomingItemsAction = UIAlertAction(title: "Clear Upcoming Items", style: UIAlertActionStyle.Default) { action in
                self.queueBasedMusicPlayer.clearUpcomingItems(fromIndex: index)
                self.tableView.reloadData()
            }
            controller.addAction(clearUpcomingItemsAction)
        }
        
        if(index != indexOfNowPlayingItem) {
            let deleteAction = UIAlertAction(title: "Delete", style:UIAlertActionStyle.Destructive) { action in
                self.tableView(self.tableView, commitEditingStyle: UITableViewCellEditingStyle.Delete,
                    forRowAtIndexPath: NSIndexPath(forRow: index, inSection: 0))
            }
            controller.addAction(deleteAction)
        }

        self.presentViewController(controller, animated: true, completion: nil)
    }
    
}

