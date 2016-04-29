//
//  NowPlayingViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class NowPlayingQueueViewController: UIViewController, DropDestination, ConfigurableAudioTableCellDelegate, GestureHandlerDelegate {

    static let instance = NowPlayingQueueViewController()
    
    private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    private var longPressGestureRecognizer:UILongPressGestureRecognizer!
    
    private (set) var laidOutSubviews:Bool = false
    private var multipleDeleteButton:UIBarButtonItem!
    
    var menuButtonTouched:Bool = false
    var isExpanded:Bool = false {
        didSet {
            if(isExpanded) {
                reloadTableData()
            } else {
                editing = false
                insertMode = false
                if !(tableView.dataSource is NowPlayingQueueDSD) || !(tableView.delegate is NowPlayingQueueDSD){
                    resetDSD()
                }
            }
            tableView.scrollsToTop = isExpanded
        }
    }
    
    var destinationTableView:UITableView {
        return tableView
    }
    
    let tableView = UITableView()
    
    
    //MARK: GESTURE PROPERTIES
    private var dragToRearrangeGestureHandler:LongPressToDragGestureHandler!
    var insertMode:Bool = false {
        didSet {
            longPressGestureRecognizer.enabled = !insertMode
            toolbarItems?.forEach() { $0.enabled = !insertMode }
        }
    }
    
    //MARK:FUNCTIONS
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
        func createFlexibleSpace() -> UIBarButtonItem {
            return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        }
        
        title = "QUEUE"
        
        ConstraintUtils.applyStandardConstraintsToView(subView: tableView, parentView: view)
        automaticallyAdjustsScrollViewInsets = false
        tableView.rowHeight = ThemeHelper.sidePanelTableViewRowHeight
        tableView.registerNib(NibContainer.songTableViewCellNib, forCellReuseIdentifier: "songDetailsTableViewCell")
        tableView.scrollsToTop = isExpanded
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.showsVerticalScrollIndicator = true
        tableView.indicatorStyle = .White
        tableView.contentInset.top = ThemeHelper.plainHeaderHight
        tableView.contentInset.bottom = 44
        
        let editButton = editButtonItem()
        let deleteButton = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(self.confirmDelete(_:)))
        let saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: #selector(self.saveCurrentQueueAsPlaylist(_:)))
		toolbarItems = [editButton, createFlexibleSpace(), deleteButton, createFlexibleSpace(), saveButton]
		toolbarItems!.forEach() { $0.tintColor = ThemeHelper.defaultTintColor }
        
        let headerView = PlainHeaderView()
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Top, .Left, .Right], subView: headerView, parentView: view)
        headerView.heightAnchor.constraintEqualToConstant(ThemeHelper.plainHeaderHight).active = true
//        ThemeHelper.applyBottomShadowToView(headerView)

        dragToRearrangeGestureHandler = LongPressToDragGestureHandler(tableView: tableView)
        dragToRearrangeGestureHandler.delegate = self
		longPressGestureRecognizer = UILongPressGestureRecognizer(target: dragToRearrangeGestureHandler, action: #selector(LongPressToDragGestureHandler.handleGesture(_:)))

        tableView.addGestureRecognizer(longPressGestureRecognizer)
        
        resetDSD()
        registerForNotifications()

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
        KyoozUtils.confirmAction(title) {
            self.commitDeletionOfIndexPaths()
        }
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
    
    private func resetDSD() {
        datasourceDelegate = NowPlayingQueueDSD(reuseIdentifier: SongDetailsTableViewCell.reuseIdentifier, audioCellDelegate: self)
    }

    //MARK: INSERT MODE FUNCITONS
    func setDropItems(dropItems: [AudioTrack], atIndex:NSIndexPath) -> Int {
        return audioQueuePlayer.insertItemsAtIndex(dropItems, index: atIndex.row)
    }
    
    func gestureDidEnd(sender: UIGestureRecognizer) {
        resetDSD()
    }

    //MARK: CLASS Functions
    func reloadTableData() {
        tableView.reloadData()
    }
    
    //for data source updates originating from the UI, we dont want to reload the table view in response to the queue changes
    //because there should already be animations taking place to reflect that content and reloading the data will interfere 
    //with the visual effect
    func reloadIfCollapsed() {
        if !isExpanded {
            reloadTableData()
        }
    }
    
    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(self.reloadTableData),
            name: AudioQueuePlayerUpdate.NowPlayingItemChanged.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(self.reloadTableData),
            name: AudioQueuePlayerUpdate.PlaybackStateUpdate.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(self.reloadTableData),
            name: AudioQueuePlayerUpdate.SystematicQueueUpdate.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(self.reloadIfCollapsed),
            name: AudioQueuePlayerUpdate.QueueUpdate.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(self.reloadTableData),
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
        return isExpanded
    }
    
    func presentActionsForCell(cell:UITableViewCell, title: String?, details: String?, originatingCenter:CGPoint) {
        guard let indexPath = tableView.indexPathForCell(cell) else {
            Logger.error("no index path found for cell with tile \(title)")
            return
        }
        let index = indexPath.row
        let mediaItem = audioQueuePlayer.nowPlayingQueue[index]

        let menuVC = KyoozMenuViewController()
		menuVC.menuTitle = title
		menuVC.menuDetails = details
        

        
        let indexOfNowPlayingItem = audioQueuePlayer.indexOfNowPlayingItem
        let lastIndex = audioQueuePlayer.nowPlayingQueue.count - 1
        
        
        var jumpToActions = [KyoozMenuActionProtocol]()
        if mediaItem.albumId != 0 {
			let goToAlbumAction = KyoozMenuAction(title: KyoozConstants.JUMP_TO_ALBUM, image: nil) {
                ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(MediaQuerySourceData(filterEntity: mediaItem, parentLibraryGroup: LibraryGrouping.Albums, baseQuery: nil)!,
                    parentGroup: LibraryGrouping.Albums, entity: mediaItem)
            }
            jumpToActions.append(goToAlbumAction)
        }
        
        if mediaItem.albumArtistId != 0 {
            let goToArtistAction = KyoozMenuAction(title: KyoozConstants.JUMP_TO_ARTIST, image: nil) {
                ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(MediaQuerySourceData(filterEntity: mediaItem, parentLibraryGroup: LibraryGrouping.Artists, baseQuery: nil)!, parentGroup: LibraryGrouping.Artists, entity: mediaItem)
            }
            jumpToActions.append(goToArtistAction)
        }
        menuVC.addActions(jumpToActions)
        
        var removeActions = [KyoozMenuActionProtocol]()
        if (!audioQueuePlayer.musicIsPlaying || index <= indexOfNowPlayingItem) && index > 0 {
            let clearPrecedingItemsAction = KyoozMenuAction(title: "REMOVE ABOVE", image: nil) {
                var indiciesToDelete = [NSIndexPath]()
                indiciesToDelete.reserveCapacity(index)
                for i in 0..<index {
                    indiciesToDelete.append(NSIndexPath(forRow: i, inSection: 0))
                }
                KyoozUtils.confirmAction("Remove the \(indiciesToDelete.count) tracks Above?", actionDetails: "Selected Track: \(title ?? "" )\n\(details ?? "")") {
                    self.audioQueuePlayer.clearItems(towardsDirection: .Above, atIndex: index)
                    self.deleteIndexPaths(indiciesToDelete)
                }
            }
            removeActions.append(clearPrecedingItemsAction)
        }
        
		let deleteAction = KyoozMenuAction(title: "REMOVE", image: nil) {
            self.datasourceDelegate.tableView?(self.tableView, commitEditingStyle: .Delete,
                forRowAtIndexPath: indexPath)
        }
        removeActions.append(deleteAction)
        
        if((!audioQueuePlayer.musicIsPlaying || index >= indexOfNowPlayingItem) && (index < lastIndex)) {
			let clearUpcomingItemsAction = KyoozMenuAction(title: "REMOVE BELOW", image:nil) {
                var indiciesToDelete = [NSIndexPath]()
                for i in (index + 1)...lastIndex {
                    indiciesToDelete.append(NSIndexPath(forRow: i, inSection: 0))
                }
                KyoozUtils.confirmAction("Remove the \(indiciesToDelete.count) tracks Below?", actionDetails: "Selected Track: \(title ?? "")\n\(details ?? "")") {
                    self.audioQueuePlayer.clearItems(towardsDirection: .Below, atIndex: index)
                    self.deleteIndexPaths(indiciesToDelete)
                }
            }
            removeActions.append(clearUpcomingItemsAction)
        }
        menuVC.addActions(removeActions)
        menuVC.addActions([KyoozMenuAction(title: KyoozConstants.ADD_TO_PLAYLIST, image: nil) {
            KyoozUtils.showAvailablePlaylistsForAddingTracks([mediaItem])
        }])
		menuVC.originatingCenter = originatingCenter
		
		KyoozUtils.showMenuViewController(menuVC)
    }

}

