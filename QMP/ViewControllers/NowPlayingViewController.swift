//
//  NowPlayingViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class NowPlayingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {

    let notificationCenter = NSNotificationCenter.defaultCenter()
    let queueBasedMusicPlayer = MusicPlayerContainer.queueBasedMusicPlayer
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.defaultCenter()
    
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
        cell.indexInQueue = indexPath.row
        cell.delegate = self
        cell.currentlyPlaying = false
        
        if(queueBasedMusicPlayer.musicIsPlaying && isNowPlayingItem(mediaItemToCompare:song)) {
            cell.currentlyPlaying = true
        }

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var index = indexPath.row
        queueBasedMusicPlayer.playItemWithIndexInCurrentQueue(index: index)
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
        return true;
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            queueBasedMusicPlayer.deleteItemAtIndexFromQueue(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
           
        }
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        queueBasedMusicPlayer.rearrangeMediaItems(sourceIndexPath.row, toIndexPath: destinationIndexPath.row)
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func reloadTableData(notification:NSNotification) {
        self.tableView.reloadData()
    }
    
    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let application = UIApplication.sharedApplication()
        notificationCenter.addObserver(self, selector: "reloadTableData:",
            name: QueueBasedMusicPlayerNoficiation.NowPlayingItemChanged.rawValue, object: queueBasedMusicPlayer)
        notificationCenter.addObserver(self, selector: "reloadTableData:",
            name: QueueBasedMusicPlayerNoficiation.PlaybackStateUpdate.rawValue, object: queueBasedMusicPlayer)
        notificationCenter.addObserver(self, selector: "reloadTableData:",
            name: QueueBasedMusicPlayerNoficiation.QueueUpdate.rawValue, object: queueBasedMusicPlayer)
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


}

    //MARK: - SongDetailsTableViewCellDelegate Methods
extension NowPlayingViewController:SongDetailsTableViewCellDelegate {

    func presentMenuItems(sender: SongDetailsTableViewCell) {
        let controller = UIAlertController(title: sender.songTitleLabel.text! + " (" + sender.albumArtistAndAlbumLabel.text! + ")", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        controller.addAction(cancelAction)

        if(!self.queueBasedMusicPlayer.musicIsPlaying || sender.indexInQueue >= queueBasedMusicPlayer.indexOfNowPlayingItem) {
            let clearUpcomingItemsAction = UIAlertAction(title: "Clear Upcoming Items", style: UIAlertActionStyle.Default) { action in
                self.queueBasedMusicPlayer.clearUpcomingItems(fromIndex: sender.indexInQueue)
                self.tableView.reloadData()
            }
            controller.addAction(clearUpcomingItemsAction)
        }
        
        let deleteAction = UIAlertAction(title: "Delete", style:UIAlertActionStyle.Destructive, handler: { action in
            self.tableView(self.tableView, commitEditingStyle: UITableViewCellEditingStyle.Delete,
                forRowAtIndexPath: NSIndexPath(forRow: sender.indexInQueue, inSection: 0))
        })
        controller.addAction(deleteAction)
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
}

