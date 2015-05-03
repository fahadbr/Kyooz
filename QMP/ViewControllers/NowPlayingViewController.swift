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

    @IBOutlet weak var toolBarEditButton: UIBarButtonItem!
    
    let notificationCenter = NSNotificationCenter.defaultCenter()
    let queueBasedMusicPlayer = MusicPlayerContainer.queueBasedMusicPlayer
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.defaultCenter()
    
    var tempImageCache = [MPMediaEntityPersistentID:UIImage]()
    var noAlbumArtCellImage:UIImage!
    var playingImage:UIImage!
    var pausedImage:UIImage!
    
    var indexPathsToDelete:[NSIndexPath]?
    var multipleDeleteButton:UIBarButtonItem!
    
    var menuButtonTouched:Bool = false
    var viewExpanded:Bool = false {
        didSet {
            if(viewExpanded) {
                reloadTableData(nil)
            } else {
                editing = false
            }
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(NibContainer.songTableViewCellNib, forCellReuseIdentifier: "songDetailsTableViewCell")
        
        toolbarItems?[0] = editButtonItem()
        registerForNotifications()
    }
    
    deinit {
        unregisterForNotifications()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func commitDeletionOfIndexPaths(sender:AnyObject?) {
        if(tableView.editing && indexPathsToDelete != nil) {
            var indicies = [Int]()
            for indexPath in indexPathsToDelete! {
                indicies.append(indexPath.row)
            }
            queueBasedMusicPlayer.deleteItemsAtIndices(indicies)
            tableView.deleteRowsAtIndexPaths(indexPathsToDelete!, withRowAnimation: UITableViewRowAnimation.Automatic)
            indexPathsToDelete!.removeAll(keepCapacity: false)
        } else if (!tableView.editing && queueBasedMusicPlayer.getNowPlayingQueue() != nil) {
            var indicies = [Int]()
            var indexPaths = [NSIndexPath]()
            for var i=0 ; i < queueBasedMusicPlayer.getNowPlayingQueue()!.count; i++ {
                if(i != queueBasedMusicPlayer.indexOfNowPlayingItem) {
                    indicies.append(i)
                    indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
                }
            }
            queueBasedMusicPlayer.deleteItemsAtIndices(indicies)
            tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
        }
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
        indexPathsToDelete = !editing ? nil : [NSIndexPath]()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("songDetailsTableViewCell", forIndexPath: indexPath) as! SongDetailsTableViewCell
        
        let mediaItem = queueBasedMusicPlayer.getNowPlayingQueue()![indexPath.row]
        let isNowPlayingItem = (indexPath.row == queueBasedMusicPlayer.indexOfNowPlayingItem)
        cell.configureTextLabelsForMediaItem(mediaItem, isNowPlayingItem:isNowPlayingItem)
        cell.albumArtImageView.image = getImageForCell(imageSize: cell.albumArtImageView.frame.size, withMediaItem: mediaItem, isNowPlayingItem:isNowPlayingItem)
        cell.delegate = self
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(tableView.editing) {
            indexPathsToDelete?.append(indexPath)
            return
        }
        
        if(menuButtonTouched) {
            presentMenuItems(forIndex: indexPath.row)
            menuButtonTouched = false
        } else {
            queueBasedMusicPlayer.playItemWithIndexInCurrentQueue(index: indexPath.row)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if(tableView.editing) {
            var indexToRemove:Int?
            var i=0
            for indexPathToDelete in indexPathsToDelete! {
                if(indexPathToDelete == indexPath) {
                    Logger.debug("removing indexPath from deletion list \(indexPath.description)")
                    indexToRemove = i
                    break;
                }
                i++
            }
            if(indexToRemove != nil) {
                indexPathsToDelete?.removeAtIndex(indexToRemove!)
            }
        }
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
        return .Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            queueBasedMusicPlayer.deleteItemsAtIndices([indexPath.row])
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
           
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
            Logger.debug("reloading now playing queue table view")
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
    
    private func getImageForCell(imageSize cellImageSize:CGSize, withMediaItem mediaItem:MPMediaItem, isNowPlayingItem:Bool) -> UIImage! {
        if(isNowPlayingItem) {
            if(!queueBasedMusicPlayer.musicIsPlaying) {
                if(playingImage == nil) {
                    playingImage = ImageContainer.resizeImage(ImageContainer.currentlyPlayingImage, toSize: cellImageSize)
                }
                return playingImage
            } else {
                if(pausedImage == nil) {
                    pausedImage = ImageContainer.resizeImage(ImageContainer.currentlyPausedImage, toSize: cellImageSize)
                }
                return pausedImage
            }
        }
        
        
        if let albumArtworkObject = mediaItem.artwork {
            var albumArtwork = tempImageCache[mediaItem.albumPersistentID]
            if(albumArtwork == nil) {
                Logger.debug("loading artwork into temp cache")
                albumArtwork = albumArtworkObject.imageWithSize(cellImageSize)
                tempImageCache[mediaItem.albumPersistentID] = albumArtwork
            }
            
            return albumArtwork
        }
        
        if(noAlbumArtCellImage == nil) {
            noAlbumArtCellImage = ImageContainer.resizeImage(ImageContainer.defaultAlbumArtworkImage, toSize: cellImageSize)
        }
        return noAlbumArtCellImage

    }

    
    private func presentMenuItems(forIndex index:Int) {
        let mediaItem = queueBasedMusicPlayer.getNowPlayingQueue()![index]
        let controller = UIAlertController(title: mediaItem.title + "\n" + mediaItem.albumArtist + " - " + mediaItem.albumTitle, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        controller.addAction(cancelAction)
        
        let indexOfNowPlayingItem = queueBasedMusicPlayer.indexOfNowPlayingItem
        let lastIndex = queueBasedMusicPlayer.getNowPlayingQueue()!.count - 1
        
        if((!queueBasedMusicPlayer.musicIsPlaying || index >= indexOfNowPlayingItem) && (index < lastIndex)) {
            let clearUpcomingItemsAction = UIAlertAction(title: "Clear Upcoming Items", style: UIAlertActionStyle.Default) { action in
                var indicesToDelete = [NSIndexPath]()
                for var i=index + 1; i <= lastIndex; i++ {
                    indicesToDelete.append(NSIndexPath(forRow: i, inSection: 0))
                }
                
                self.queueBasedMusicPlayer.clearUpcomingItems(fromIndex: index)
                self.tableView.deleteRowsAtIndexPaths(indicesToDelete, withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            controller.addAction(clearUpcomingItemsAction)
        }
        

        let deleteAction = UIAlertAction(title: "Delete", style:UIAlertActionStyle.Destructive) { action in
            self.tableView(self.tableView, commitEditingStyle: UITableViewCellEditingStyle.Delete,
                forRowAtIndexPath: NSIndexPath(forRow: index, inSection: 0))
        }
        controller.addAction(deleteAction)

        self.presentViewController(controller, animated: true, completion: nil)
    }
    
}

