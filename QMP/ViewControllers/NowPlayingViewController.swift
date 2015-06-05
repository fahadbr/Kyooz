//
//  NowPlayingViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class NowPlayingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DropDestination {

    @IBOutlet weak var toolBarEditButton: UIBarButtonItem!
    
    private let notificationCenter = NSNotificationCenter.defaultCenter()
    private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.defaultCenter()
    
    private var longPressGestureRecognizer:UILongPressGestureRecognizer!
    private var menuButtonTapGestureRecognizer:UITapGestureRecognizer!
    
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
    
    var destinationTableView:UITableView {
        get {
            return tableView
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    
    //MARK: GESTURE PROPERTIES
    private var dragToRearrangeGestureHandler:LongPressToDragGestureHandler!
    
    var indexPathOfMovingItem:NSIndexPath!
    var insertMode:Bool = false {
        didSet {
            if(insertMode) {
                longPressGestureRecognizer.enabled = false
                for item in toolbarItems! {
                    (item as? UIBarButtonItem)?.enabled = false
                }
            } else {
                longPressGestureRecognizer.enabled = true
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
        

        dragToRearrangeGestureHandler = LongPressToDragGestureHandler(tableView: tableView)
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: dragToRearrangeGestureHandler, action: "handleGesture:")
        menuButtonTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTapGesture:")
        tableView.addGestureRecognizer(longPressGestureRecognizer)
        tableView.addGestureRecognizer(menuButtonTapGestureRecognizer)
        registerForNotifications()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
            audioQueuePlayer.deleteItemsAtIndices(indicies)
            tableView.deleteRowsAtIndexPaths(indexPathsToDelete!, withRowAnimation: UITableViewRowAnimation.Automatic)
            indexPathsToDelete!.removeAll(keepCapacity: false)
        } else if (!tableView.editing && !audioQueuePlayer.nowPlayingQueue.isEmpty) {
            var indicies = [Int]()
            var indexPaths = [NSIndexPath]()
            for var i=0 ; i < audioQueuePlayer.nowPlayingQueue.count; i++ {
                if(i != audioQueuePlayer.indexOfNowPlayingItem) {
                    indicies.append(i)
                    indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
                }
            }
            audioQueuePlayer.deleteItemsAtIndices(indicies)
            tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = audioQueuePlayer.nowPlayingQueue.count
        return insertMode ? (count + 1) : count
    }

    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
        indexPathsToDelete = !editing ? nil : [NSIndexPath]()
        menuButtonTapGestureRecognizer.enabled = !editing
        longPressGestureRecognizer.enabled = !editing
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if(insertMode && indexPath.row == indexPathOfMovingItem.row) {
            var cell = UITableViewCell()
            cell.backgroundColor = UIColor(white: 0.9, alpha: 0.5)
            cell.textLabel?.text = "Insert Here"
            cell.textLabel?.textAlignment = NSTextAlignment.Center
            cell.textLabel?.font = ThemeHelper.defaultFont
            cell.textLabel?.textColor = UIColor(white: 0.1, alpha: 0.5)
            return cell
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("songDetailsTableViewCell", forIndexPath: indexPath) as! SongDetailsTableViewCell
        var indexToUse = indexPath.row
        if(insertMode && indexPathOfMovingItem.row < indexPath.row){
            indexToUse--
        }
    
        let mediaItem = audioQueuePlayer.nowPlayingQueue[indexToUse]
        let isNowPlayingItem = (indexToUse == audioQueuePlayer.indexOfNowPlayingItem)
        cell.configureTextLabelsForMediaItem(mediaItem, isNowPlayingItem:isNowPlayingItem)
        cell.albumArtImageView.image = getImageForCell(imageSize: cell.albumArtImageView.frame.size, withMediaItem: mediaItem, isNowPlayingItem:isNowPlayingItem)
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(tableView.editing) {
            indexPathsToDelete?.append(indexPath)
            return
        }
        
        audioQueuePlayer.playItemWithIndexInCurrentQueue(index: indexPath.row)
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
    
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            audioQueuePlayer.deleteItemsAtIndices([indexPath.row])
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        audioQueuePlayer.moveMediaItem(fromIndexPath:sourceIndexPath.row, toIndexPath: destinationIndexPath.row)
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    //MARK: INSERT MODE FUNCITONS
    
    func setDropItems(dropItems: [MPMediaItem], atIndex:NSIndexPath) {
        audioQueuePlayer.insertItemsAtIndex(dropItems, index: atIndex.row)
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
            name: AudioQueuePlayerUpdate.NowPlayingItemChanged.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadTableData:",
            name: AudioQueuePlayerUpdate.PlaybackStateUpdate.rawValue, object: audioQueuePlayer)
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func getImageForCell(imageSize cellImageSize:CGSize, withMediaItem mediaItem:MPMediaItem, isNowPlayingItem:Bool) -> UIImage! {
        if(isNowPlayingItem) {
            if(!audioQueuePlayer.musicIsPlaying) {
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
    func handleTapGesture(sender:UITapGestureRecognizer) {
        let location = sender.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(location)
        if(indexPath == nil) { return }
        
        let touchedCell = tableView.cellForRowAtIndexPath(indexPath!)! as! SongDetailsTableViewCell
        let locationInMenuButton = sender.locationInView(touchedCell.menuButton)
        if(!touchedCell.menuButton.pointInside(locationInMenuButton, withEvent: nil)) {
            tableView(tableView, didSelectRowAtIndexPath: indexPath!)
            return
        }
        
        let index = indexPath!.row
        
        let mediaItem = audioQueuePlayer.nowPlayingQueue[index]
        let controller = UIAlertController(title: mediaItem.title + "\n" + mediaItem.albumArtist + " - " + mediaItem.albumTitle, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        controller.addAction(cancelAction)
        
        let indexOfNowPlayingItem = audioQueuePlayer.indexOfNowPlayingItem
        let lastIndex = audioQueuePlayer.nowPlayingQueue.count - 1
        
        if((!audioQueuePlayer.musicIsPlaying || index >= indexOfNowPlayingItem) && (index < lastIndex)) {
            let clearUpcomingItemsAction = UIAlertAction(title: "Clear Upcoming Tracks", style: UIAlertActionStyle.Default) { action in
                var indicesToDelete = [NSIndexPath]()
                for var i=index + 1; i <= lastIndex; i++ {
                    indicesToDelete.append(NSIndexPath(forRow: i, inSection: 0))
                }
                
                self.audioQueuePlayer.clearUpcomingItems(fromIndex: index)
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

}

