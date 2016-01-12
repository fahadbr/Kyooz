//
//  NowPlayingViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class NowPlayingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DropDestination {

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
    private var insertCellView:UITableViewCell!
    
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
    
    var indexPathOfMovingItem:NSIndexPath! {
        didSet {
            if indexPathOfMovingItem == nil { return }
            if indexPathOfMovingItem.row == audioQueuePlayer.nowPlayingQueue.count || indexPathOfMovingItem.row == 0 {
                insertCellView.hidden = false
            } else {
                insertCellView.hidden = true
            }
        }
    }
    var insertModeCount:Int!
    var insertMode:Bool = false {
        didSet {
            if(insertMode) {
                insertModeCount = audioQueuePlayer.nowPlayingQueue.count + 1
            } else {
                indexPathOfMovingItem = nil
            }
            longPressGestureRecognizer.enabled = !insertMode
            for item in toolbarItems! {
                item.enabled = !insertMode
            }
        }
    }
    
    //MARK:FUNCTIONS
    
    @IBAction func showSettings(sender: AnyObject) {
        ContainerViewController.instance.pushViewController(UIStoryboard.settingsViewController())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(NibContainer.songTableViewCellNib, forCellReuseIdentifier: "songDetailsTableViewCell")
        let editButton = editButtonItem()
        editButton.tintColor = ThemeHelper.defaultTintColor
        toolbarItems?[0] = editButton
        

        dragToRearrangeGestureHandler = LongPressToDragGestureHandler(tableView: tableView)
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: dragToRearrangeGestureHandler, action: "handleGesture:")
        menuButtonTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTapGesture:")
        tableView.addGestureRecognizer(longPressGestureRecognizer)
        tableView.addGestureRecognizer(menuButtonTapGestureRecognizer)
        
        let cell = UITableViewCell()
        cell.backgroundColor = ThemeHelper.defaultTableCellColor
        cell.textLabel?.text = "Insert Here"
        cell.textLabel?.textAlignment = NSTextAlignment.Center
        cell.textLabel?.font = ThemeHelper.defaultFont
        cell.textLabel?.textColor = UIColor.grayColor()
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        cell.layer.shouldRasterize = true
        cell.hidden = true
        insertCellView = cell
        
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
        tempImageCache.removeAll()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func commitDeletionOfIndexPaths(sender:AnyObject?) {
        if(tableView.editing && indexPathsToDelete != nil) {
            var indicies = [Int]()
            for indexPath in indexPathsToDelete! {
                indicies.append(indexPath.row)
            }
            audioQueuePlayer.deleteItemsAtIndices(indicies)
            deleteIndexPaths(indexPathsToDelete!)
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
            audioQueuePlayer.clearItems(towardsDirection: .All, atIndex: audioQueuePlayer.indexOfNowPlayingItem)
            deleteIndexPaths(indexPaths)
        }
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = audioQueuePlayer.nowPlayingQueue.count
        return insertMode ? insertModeCount : count
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
            return insertCellView
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("songDetailsTableViewCell", forIndexPath: indexPath) as! SongDetailsTableViewCell
        var indexToUse = indexPath.row
        if(insertMode && indexPathOfMovingItem.row < indexPath.row){
            indexToUse--
        }
    
        let mediaItem = audioQueuePlayer.nowPlayingQueue[indexToUse]
        let isNowPlayingItem = (indexToUse == audioQueuePlayer.indexOfNowPlayingItem)
        cell.configureTextLabelsForMediaItem(mediaItem, isNowPlayingItem:isNowPlayingItem)
        cell.albumArtImageView.image = self.getImageForCell(imageSize: cell.albumArtImageView.frame.size, withMediaItem: mediaItem, isNowPlayingItem:isNowPlayingItem)
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
    
    func setDropItems(dropItems: [AudioTrack], atIndex:NSIndexPath) {
        audioQueuePlayer.insertItemsAtIndex(dropItems, index: atIndex.row)
    }
    

    //MARK: CLASS Functions
    func reloadTableData(notification:NSNotification?) {
        tableView.reloadData()
    }
    
    func reloadIfCollapsed(notification:NSNotification?) {
        if !viewExpanded {
            reloadTableData(notification)
        }
    }
    
    
    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "reloadTableData:",
            name: AudioQueuePlayerUpdate.NowPlayingItemChanged.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadTableData:",
            name: AudioQueuePlayerUpdate.PlaybackStateUpdate.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadTableData:",
            name: AudioQueuePlayerUpdate.SystematicQueueUpdate.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadIfCollapsed:",
            name: AudioQueuePlayerUpdate.QueueUpdate.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadTableData:",
            name: UIApplicationDidBecomeActiveNotification, object: UIApplication.sharedApplication())
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func getImageForCell(imageSize cellImageSize:CGSize, withMediaItem mediaItem:AudioTrack, isNowPlayingItem:Bool) -> UIImage! {
        
        if let albumArtworkObject = mediaItem.artwork {
            var albumArtwork = tempImageCache[mediaItem.albumId]
            if(albumArtwork == nil) {
                albumArtwork = albumArtworkObject.imageWithSize(cellImageSize)
                tempImageCache[mediaItem.albumId] = albumArtwork
            }
            
            return albumArtwork
        }
        
        if(noAlbumArtCellImage == nil) {
            noAlbumArtCellImage = ImageContainer.resizeImage(ImageContainer.defaultAlbumArtworkImage, toSize: cellImageSize)
        }
        return noAlbumArtCellImage

    }
    
    private func deleteIndexPaths(indiciesToDelete:[NSIndexPath]) {
        if indiciesToDelete.isEmpty { return }
        
        if indiciesToDelete.count < 250 {
            tableView.deleteRowsAtIndexPaths(indiciesToDelete, withRowAnimation: .Automatic)
        } else {
            tableView.beginUpdates()
            tableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            tableView.insertSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            tableView.endUpdates()
        }
    }
    
    //MARK: - Scroll View Delegate
    final func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        return viewExpanded
    }

    //MARK: gesture recognizer handlers
    func handleTapGesture(sender:UITapGestureRecognizer) {
        let location = sender.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(location)
        if(indexPath == nil) { return }
        
        let touchedCell = tableView.cellForRowAtIndexPath(indexPath!)! as! SongDetailsTableViewCell
        let locationInMenuButton = sender.locationInView(touchedCell.menuButtonActionArea)
        if(!touchedCell.menuButtonActionArea.pointInside(locationInMenuButton, withEvent: nil)) {
            tableView(tableView, didSelectRowAtIndexPath: indexPath!)
            return
        }
        
        let index = indexPath!.row
        
        let mediaItem = audioQueuePlayer.nowPlayingQueue[index]
        let actionTitle = "\(mediaItem.trackTitle)\n\(mediaItem.albumArtist ?? mediaItem.artist ?? "Unknown Artist") - \(mediaItem.albumTitle ?? "Unknown Album")"
        let controller = UIAlertController(title: actionTitle, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        controller.addAction(cancelAction)
        
        let indexOfNowPlayingItem = audioQueuePlayer.indexOfNowPlayingItem
        let lastIndex = audioQueuePlayer.nowPlayingQueue.count - 1
        
        
        if mediaItem.albumId != 0 {
            let goToAlbumAction = UIAlertAction(title: "Go To Album", style: .Default) { action in
                ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(basePredicates: nil, parentGroup: LibraryGrouping.Albums, entity: mediaItem as! MPMediaItem)
            }
            controller.addAction(goToAlbumAction)
        }
        
        if mediaItem.albumArtistId != 0 {
            let goToArtistAction = UIAlertAction(title: "Go To Artist", style: .Default) { action in
                ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(basePredicates: nil, parentGroup: LibraryGrouping.Artists, entity: mediaItem as! MPMediaItem)
            }
            controller.addAction(goToArtistAction)
        }
        
        if (!audioQueuePlayer.musicIsPlaying || index <= indexOfNowPlayingItem) && index > 0 {
            let clearPrecedingItemsAction = UIAlertAction(title: "Remove Above", style: .Destructive) { action in
                var indiciesToDelete = [NSIndexPath]()
                indiciesToDelete.reserveCapacity(index)
                for i in 0..<index {
                    indiciesToDelete.append(NSIndexPath(forRow: i, inSection: 0))
                }
                self.audioQueuePlayer.clearItems(towardsDirection: .Above, atIndex: index)
                self.deleteIndexPaths(indiciesToDelete)
            }
            controller.addAction(clearPrecedingItemsAction)
        }
        
        let deleteAction = UIAlertAction(title: "Remove", style: .Destructive) { action in
            self.tableView(self.tableView, commitEditingStyle: .Delete,
                forRowAtIndexPath: NSIndexPath(forRow: index, inSection: 0))
        }
        controller.addAction(deleteAction)
        
        if((!audioQueuePlayer.musicIsPlaying || index >= indexOfNowPlayingItem) && (index < lastIndex)) {
            let clearUpcomingItemsAction = UIAlertAction(title: "Remove Below", style: .Destructive) { action in
                var indiciesToDelete = [NSIndexPath]()
                for i in (index + 1)...lastIndex {
                    indiciesToDelete.append(NSIndexPath(forRow: i, inSection: 0))
                }
                self.audioQueuePlayer.clearItems(towardsDirection: .Below, atIndex: index)
                self.deleteIndexPaths(indiciesToDelete)
            }
            controller.addAction(clearUpcomingItemsAction)
        }
        
        self.presentViewController(controller, animated: true, completion: nil)
    }

}

