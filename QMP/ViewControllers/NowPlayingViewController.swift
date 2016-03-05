//
//  NowPlayingViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class NowPlayingViewController: UIViewController, DropDestination, ConfigurableAudioTableCellDelegate, UIScrollViewDelegate {

    @IBOutlet weak var toolBarEditButton: UIBarButtonItem!
    
    private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    private var longPressGestureRecognizer:UILongPressGestureRecognizer!
    
    private (set) var laidOutSubviews:Bool = false
    private var multipleDeleteButton:UIBarButtonItem!
    
    var menuButtonTouched:Bool = false
    var viewExpanded:Bool = false {
        didSet {
            if(viewExpanded) {
                reloadTableData()
            } else {
                editing = false
                insertMode = false
                if !(datasourceDelegate is NowPlayingQueueDSD) {
                    datasourceDelegate = NowPlayingQueueDSD(reuseIdentifier: SongDetailsTableViewCell.reuseIdentifier, audioCellDelegate: self)
                }
            }
        }
    }
    
    var destinationTableView:UITableView {
        return tableView
    }
    
    @IBOutlet var tableView: UITableView!
    
    
    //MARK: GESTURE PROPERTIES
    private var dragToRearrangeGestureHandler:LongPressToDragGestureHandler!
    
    var indexPathOfMovingItem:NSIndexPath! {
        didSet {
            (datasourceDelegate as? DragAndDropDSDWrapper)?.indexPathOfMovingItem = indexPathOfMovingItem
        }
    }
    var insertMode:Bool = false {
        didSet {
            if(insertMode) {
                datasourceDelegate = DragAndDropDSDWrapper(datasourceDelegate: datasourceDelegate)
            } else {
                if let dragAndDropDSDWrapper = datasourceDelegate as? DragAndDropDSDWrapper {
                    dragAndDropDSDWrapper.endingInsert = true
                }
            }
            longPressGestureRecognizer.enabled = !insertMode
            toolbarItems?.forEach() { $0.enabled = !insertMode }
        }
    }
    
    //MARK:FUNCTIONS
    
    @IBAction func showSettings(sender: AnyObject) {
        ContainerViewController.instance.pushViewController(UIStoryboard.settingsViewController())
    }
    
    var datasourceDelegate:AudioEntityDSDProtocol! {
        didSet {
            tableView.dataSource = datasourceDelegate
            tableView.delegate = datasourceDelegate
        }
    }
    
    deinit {
        unregisterForNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(NibContainer.songTableViewCellNib, forCellReuseIdentifier: "songDetailsTableViewCell")
        let editButton = editButtonItem()
        editButton.tintColor = ThemeHelper.defaultTintColor
        toolbarItems?[0] = editButton
        

        dragToRearrangeGestureHandler = LongPressToDragGestureHandler(tableView: tableView)
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: dragToRearrangeGestureHandler, action: "handleGesture:")
        tableView.addGestureRecognizer(longPressGestureRecognizer)
        
        datasourceDelegate = NowPlayingQueueDSD(reuseIdentifier: SongDetailsTableViewCell.reuseIdentifier, audioCellDelegate: self)
        registerForNotifications()

    }
	
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        laidOutSubviews = true
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
        longPressGestureRecognizer.enabled = !editing
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveCurrentQueueAsPlaylist(sender:AnyObject?) {
        KyoozUtils.showPlaylistCreationControllerForTracks(audioQueuePlayer.nowPlayingQueue)
    }
    
    @IBAction func confirmDelete(sender:AnyObject?) {
        let title = tableView.editing ? "Remove the \(tableView.indexPathsForSelectedRows?.count ?? 0) selected tracks?" : "Remove the entire queue?"
        showConfirmDeleteAlertController(title) {
            self.commitDeletionOfIndexPaths()
        }
    }
    
	private func showConfirmDeleteAlertController(title:String, details:String? = nil, deleteBlock:()->Void) {
        let ac = UIAlertController(title: title, message: details, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "Yes", style: .Destructive, handler: {_ in deleteBlock() }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(ac, animated: true, completion: nil)

    }
    
    private func commitDeletionOfIndexPaths() {
        if let indexPathsToDelete = tableView.indexPathsForSelectedRows where tableView.editing {
            let indicies = indexPathsToDelete.map() { $0.row }
            audioQueuePlayer.deleteItemsAtIndices(indicies)
            deleteIndexPaths(indexPathsToDelete)
        } else if (!tableView.editing && !audioQueuePlayer.nowPlayingQueue.isEmpty) {
            var indexPaths = [NSIndexPath]()
            let count = audioQueuePlayer.nowPlayingQueue.count
            
            indexPaths.reserveCapacity(count)
            
            let indexOfNowPlayingItem = audioQueuePlayer.indexOfNowPlayingItem
            for i in 0 ..< count {
                if i != indexOfNowPlayingItem {
                    indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
                }
            }
            audioQueuePlayer.clearItems(towardsDirection: .All, atIndex: audioQueuePlayer.indexOfNowPlayingItem)
            deleteIndexPaths(indexPaths)
        }
    }

    //MARK: INSERT MODE FUNCITONS
    func setDropItems(dropItems: [AudioTrack], atIndex:NSIndexPath) -> Int {
        return audioQueuePlayer.insertItemsAtIndex(dropItems, index: atIndex.row)
    }

    //MARK: CLASS Functions
    func reloadTableData() {
        tableView.reloadData()
    }
    
    //for data source updates originating from the UI, we dont want to reload the table view in response to the queue changes
    //because there should already be animations taking place to reflect that content and reloading the data will interfere 
    //with the visual effect
    func reloadIfCollapsed() {
        if !viewExpanded {
            reloadTableData()
        }
    }
    
    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "reloadTableData",
            name: AudioQueuePlayerUpdate.NowPlayingItemChanged.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadTableData",
            name: AudioQueuePlayerUpdate.PlaybackStateUpdate.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadTableData",
            name: AudioQueuePlayerUpdate.SystematicQueueUpdate.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadIfCollapsed",
            name: AudioQueuePlayerUpdate.QueueUpdate.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadTableData",
            name: UIApplicationDidBecomeActiveNotification, object: UIApplication.sharedApplication())
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
    
    func presentActionsForIndexPath(indexPath: NSIndexPath, title: String?, details: String?) {
        let index = indexPath.row
        let mediaItem = audioQueuePlayer.nowPlayingQueue[index]

        let controller = UIAlertController(title: title, message: details, preferredStyle: UIAlertControllerStyle.Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        controller.addAction(cancelAction)
        
        let indexOfNowPlayingItem = audioQueuePlayer.indexOfNowPlayingItem
        let lastIndex = audioQueuePlayer.nowPlayingQueue.count - 1
        
        
        if mediaItem.albumId != 0 {
            let goToAlbumAction = UIAlertAction(title: "Jump To Album", style: .Default) { action in
                ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(MediaQuerySourceData(filterEntity: mediaItem, parentLibraryGroup: LibraryGrouping.Albums, baseQuery: nil)!,
                    parentGroup: LibraryGrouping.Albums, entity: mediaItem)
            }
            controller.addAction(goToAlbumAction)
        }
        
        if mediaItem.albumArtistId != 0 {
            let goToArtistAction = UIAlertAction(title: "Jump To Artist", style: .Default) { action in
                ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(MediaQuerySourceData(filterEntity: mediaItem, parentLibraryGroup: LibraryGrouping.Artists, baseQuery: nil)!, parentGroup: LibraryGrouping.Artists, entity: mediaItem)
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
                self.showConfirmDeleteAlertController("Remove the \(indiciesToDelete.count) tracks Above?", details: "Selected Track: \(title ?? "" )\n\(details ?? "")") {
                    self.audioQueuePlayer.clearItems(towardsDirection: .Above, atIndex: index)
                    self.deleteIndexPaths(indiciesToDelete)
                }
            }
            controller.addAction(clearPrecedingItemsAction)
        }
        
        let deleteAction = UIAlertAction(title: "Remove", style: .Destructive) { action in
            self.datasourceDelegate.tableView?(self.tableView, commitEditingStyle: .Delete,
                forRowAtIndexPath: indexPath)
        }
        controller.addAction(deleteAction)
        
        if((!audioQueuePlayer.musicIsPlaying || index >= indexOfNowPlayingItem) && (index < lastIndex)) {
            let clearUpcomingItemsAction = UIAlertAction(title: "Remove Below", style: .Destructive) { action in
                var indiciesToDelete = [NSIndexPath]()
                for i in (index + 1)...lastIndex {
                    indiciesToDelete.append(NSIndexPath(forRow: i, inSection: 0))
                }
                self.showConfirmDeleteAlertController("Remove the \(indiciesToDelete.count) tracks Below?", details: "Selected Track: \(title ?? "")\n\(details ?? "")") {
                    self.audioQueuePlayer.clearItems(towardsDirection: .Below, atIndex: index)
                    self.deleteIndexPaths(indiciesToDelete)
                }
            }
            controller.addAction(clearUpcomingItemsAction)
        }
        
        presentViewController(controller, animated: true, completion: nil)
    }

}

