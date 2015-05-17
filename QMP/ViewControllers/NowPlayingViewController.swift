//
//  NowPlayingViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class NowPlayingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TableViewScollPositionControllerDelegate  {

    @IBOutlet weak var toolBarEditButton: UIBarButtonItem!
    
    private let notificationCenter = NSNotificationCenter.defaultCenter()
    private let queueBasedMusicPlayer = MusicPlayerContainer.queueBasedMusicPlayer
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.defaultCenter()
    private let timeDelayInNanoSeconds = Int64(0.50 * Double(NSEC_PER_SEC))
    
    private var longPressGestureRecognizer:UILongPressGestureRecognizer!
    private var menuButtonTapGestureRecognizer:UITapGestureRecognizer!
    private var tableViewScrollPositionController:TableViewScrollPositionController?
    
    private var tempImageCache = [MPMediaEntityPersistentID:UIImage]()
    private var noAlbumArtCellImage:UIImage!
    private var playingImage:UIImage!
    private var pausedImage:UIImage!
    
    
    private (set) var laidOutSubviews:Bool = false
    private var indexPathsToDelete:[NSIndexPath]?
    private var multipleDeleteButton:UIBarButtonItem!
    
    var menuButtonTouched:Bool = false
    var viewExpanded:Bool = false {
        didSet {
            if(viewExpanded) {
                reloadTableData(nil)
            } else {
                editing = false
                insertMode = false
            }
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    
    //MARK: GESTURE PROPERTIES
    private (set) var indexPathOfMovingItem:NSIndexPath!
    private var snapshot:UIView!
    private var beginningAnimationEnded:Bool = false
    private var itemsToInsert:[MPMediaItem]?
    private var insertMode:Bool = false {
        didSet {
            if(insertMode) {
                longPressGestureRecognizer.enabled = false
                for item in toolbarItems! {
                    (item as? UIBarButtonItem)?.enabled = false
                }
            } else {
                longPressGestureRecognizer.enabled = true
                itemsToInsert = nil
                indexPathOfMovingItem = nil
                for item in toolbarItems! {
                    (item as? UIBarButtonItem)?.enabled = true
                }
            }
        }
    }
    
    //MARK:FUNCTIONS
    
    @IBAction func showSettings(sender: AnyObject) {
        ContainerViewController.instance.presentSettingsViewController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(NibContainer.songTableViewCellNib, forCellReuseIdentifier: "songDetailsTableViewCell")
        var editButton = editButtonItem()
        editButton.tintColor = UIColor.blackColor()
        toolbarItems?[0] = editButton
        
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPressGesture:")
        menuButtonTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "presentMenuItems:")
        tableView.addGestureRecognizer(longPressGestureRecognizer)
        tableView.addGestureRecognizer(menuButtonTapGestureRecognizer)
        registerForNotifications()
    }
    
    override func viewDidLayoutSubviews() {
        laidOutSubviews = true
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
            return insertMode ? (count + 1) : count
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
        if(insertMode && indexPath.row == indexPathOfMovingItem.row) {
            var cell = UITableViewCell()
            cell.backgroundColor = UIColor.lightGrayColor()
            return cell
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("songDetailsTableViewCell", forIndexPath: indexPath) as! SongDetailsTableViewCell
        var indexToUse = indexPath.row
        if(insertMode && indexPathOfMovingItem.row < indexPath.row){
            indexToUse--
        }
    
        let mediaItem = queueBasedMusicPlayer.getNowPlayingQueue()![indexToUse]
        let isNowPlayingItem = (indexToUse == queueBasedMusicPlayer.indexOfNowPlayingItem)
        cell.configureTextLabelsForMediaItem(mediaItem, isNowPlayingItem:isNowPlayingItem)
        cell.albumArtImageView.image = getImageForCell(imageSize: cell.albumArtImageView.frame.size, withMediaItem: mediaItem, isNowPlayingItem:isNowPlayingItem)
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(tableView.editing) {
            indexPathsToDelete?.append(indexPath)
            return
        }
        
        queueBasedMusicPlayer.playItemWithIndexInCurrentQueue(index: indexPath.row)
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
    
    //MARK: INSERT MODE FUNCITONS
    func initiateInsertMode(mediaItems:[MPMediaItem], sender:UILongPressGestureRecognizer) {
        let location = sender.locationInView(tableView)

        var indexPath = tableView.indexPathForRowAtPoint(CGPoint(x: 0, y: location.y))
        if(indexPath == nil) {
            indexPath = NSIndexPath(forRow: queueBasedMusicPlayer.getNowPlayingQueue()?.count ?? 0, inSection: 0)
        }
        insertMode = true
        itemsToInsert = mediaItems
        indexPathOfMovingItem = indexPath
        tableView.insertRowsAtIndexPaths([indexPathOfMovingItem], withRowAnimation: UITableViewRowAnimation.Automatic)
        tableViewScrollPositionController = TableViewScrollPositionController(tableView: tableView, delegate:self, updatesDataSource:false)

    }
    
    func endInsertMode(sender:UILongPressGestureRecognizer) {
        let location = sender.locationInView(tableView)
        let insideTableView = tableView.pointInside(location, withEvent: nil)
        let localItemsToInsert = itemsToInsert!
        let localIndexPathForInserting = indexPathOfMovingItem
        
        insertMode = false
        tableViewScrollPositionController?.invalidateTimer()
        tableViewScrollPositionController = nil
        tableView.deleteRowsAtIndexPaths([localIndexPathForInserting], withRowAnimation: UITableViewRowAnimation.Fade)
        
        if(insideTableView) {
            var indexPaths = [NSIndexPath]()
            let startingIndex = localIndexPathForInserting.row
            for index in (startingIndex)..<(startingIndex+localItemsToInsert.count)  {
                indexPaths.append(NSIndexPath(forRow: index, inSection: 0))
            }

            queueBasedMusicPlayer.insertItemsAtIndex(localItemsToInsert, index: startingIndex)
            tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Fade)
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeDelayInNanoSeconds), dispatch_get_main_queue()) { [weak self]() in
            Logger.debug("ending insert mode and clearing data")
            self?.insertMode = false
            ContainerViewController.instance.animateSidePanel(shouldExpand: false)
        }
        
    }
    
    func handleInsertPositionChanged(sender:UILongPressGestureRecognizer) {
        if let location = handlePositionChange(sender, updateDataSource:false) {
            tableViewScrollPositionController?.startScrollingWithLocation(location, gestureRecognizer:sender)
        }
    }
    
    func handlePositionChange(sender: UILongPressGestureRecognizer, updateDataSource:Bool) -> CGPoint? {
        let location = sender.locationInView(tableView)
        let insideTableView = tableView.pointInside(location, withEvent: nil)
        if(insideTableView) {
            snapshot?.center.y = location.y
            let indexPath = tableView.indexPathForRowAtPoint(location)
            if(indexPath != nil && !indexPathOfMovingItem.isEqual(indexPath)) {
                if(updateDataSource) {
                    queueBasedMusicPlayer.moveMediaItem(fromIndexPath: indexPathOfMovingItem.row, toIndexPath: indexPath!.row)
                }
                tableView.moveRowAtIndexPath(indexPathOfMovingItem, toIndexPath: indexPath!)
                indexPathOfMovingItem = indexPath!
            }
            return location
        } else {
            tableViewScrollPositionController?.invalidateTimer()
        }
        return nil
    }
    

    
    //MARK: CLASS Functions
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

    //MARK: gesture recognizer handlers
    func presentMenuItems(sender:UITapGestureRecognizer) {
        let location = sender.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(location)
        if(indexPath == nil) { return }
        
        let touchedCell = tableView.cellForRowAtIndexPath(indexPath!)! as! SongDetailsTableViewCell
        let locationInMenuButton = sender.locationInView(touchedCell.menuButton)
        if(!touchedCell.menuButton.pointInside(locationInMenuButton, withEvent: nil)) { return }
        
        let index = indexPath!.row
        
        let mediaItem = queueBasedMusicPlayer.getNowPlayingQueue()![index]
        let controller = UIAlertController(title: mediaItem.title + "\n" + mediaItem.albumArtist + " - " + mediaItem.albumTitle, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        controller.addAction(cancelAction)
        
        let indexOfNowPlayingItem = queueBasedMusicPlayer.indexOfNowPlayingItem
        let lastIndex = queueBasedMusicPlayer.getNowPlayingQueue()!.count - 1
        
        if((!queueBasedMusicPlayer.musicIsPlaying || index >= indexOfNowPlayingItem) && (index < lastIndex)) {
            let clearUpcomingItemsAction = UIAlertAction(title: "Clear Upcoming Tracks", style: UIAlertActionStyle.Default) { action in
                var indicesToDelete = [NSIndexPath]()
                for var i=index + 1; i <= lastIndex; i++ {
                    indicesToDelete.append(NSIndexPath(forRow: i, inSection: 0))
                }
                
                self.queueBasedMusicPlayer.clearUpcomingItems(fromIndex: index)
                self.tableView.deleteRowsAtIndexPaths(indicesToDelete, withRowAnimation: UITableViewRowAnimation.Bottom)
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
    
    func handleLongPressGesture(sender:UILongPressGestureRecognizer) {

        let state:UIGestureRecognizerState = sender.state
        
        switch(state) {
        case .Began:

            let location = sender.locationInView(tableView)
            let indexPath:NSIndexPath? = tableView.indexPathForRowAtPoint(location)
            
            if let sourceIndexPath = indexPath {
                indexPathOfMovingItem = sourceIndexPath
                let cell = tableView.cellForRowAtIndexPath(sourceIndexPath)!
                cell.highlighted = false
                //take a snapshot of the selected row using a helper method
                snapshot = ImageHelper.customSnapshotFromView(cell)
                
                //add the snapshot as a subview, centered at cell's center
                snapshot.center = cell.center
                snapshot.alpha = 0.0
                tableView.addSubview(snapshot)
                beginningAnimationEnded = false
                tableViewScrollPositionController = TableViewScrollPositionController(tableView: tableView, delegate: self, updatesDataSource:true)
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    
                    //Offest for gesture location
                    self.snapshot.center.y = cell.center.y
                    self.snapshot.transform = CGAffineTransformMakeScale(1.10, 1.10)
                    self.snapshot.alpha = 0.80
                    
                    //Fade out the cell in the tableview
                    cell.alpha = 0.0
                    
                    }, completion: {(finished:Bool) in
                        cell.hidden = true
                        self.beginningAnimationEnded = true
                } )
            }
        case .Changed:
            if let location = handlePositionChange(sender, updateDataSource:true) {
                tableViewScrollPositionController?.startScrollingWithLocation(location, gestureRecognizer: sender)
            }
        default:
            if(!beginningAnimationEnded) {
                //if the beginning animation hasnt ended yet, we must wait until it is
                //so we call the method again to retry
                dispatch_async(dispatch_get_main_queue()) { [weak self]() in
                    self?.handleLongPressGesture(sender)
                }
                return
            }
            tableViewScrollPositionController?.invalidateTimer()
            tableViewScrollPositionController = nil
            
            let cell = self.tableView.cellForRowAtIndexPath(indexPathOfMovingItem)!
            cell.hidden = false
            cell.alpha = 0.0
            
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.snapshot.center = cell.center
                self.snapshot.transform = CGAffineTransformIdentity
                self.snapshot.alpha = 0.0
                
                //undo fade out
                cell.alpha = 1.0
            }, completion: { (finished:Bool) -> Void in
                self.snapshot.removeFromSuperview()
                self.snapshot = nil
                self.indexPathOfMovingItem = nil
            })
        }
    }
    
    

}

