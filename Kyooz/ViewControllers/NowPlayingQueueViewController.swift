//
//  NowPlayingQueueViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class NowPlayingQueueViewController: UIViewController, DropDestination, AudioTableCellDelegate, GestureHandlerDelegate {

    static let instance = NowPlayingQueueViewController()
    
    private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    private let tableFooterView = KyoozTableFooterView()
    private var longPressGestureRecognizer:UILongPressGestureRecognizer!
    
    private (set) var laidOutSubviews:Bool = false
    private var multipleDeleteButton:UIBarButtonItem!
	
	var shouldAnimateInArtwork: Bool { return false }
    var menuButtonTouched:Bool = false
    var isExpanded:Bool = false {
        didSet {
            if isExpanded {
                reloadTableData()
                KyoozUtils.doInMainQueueAfterDelay(0.5) {
                    if !self.insertMode && self.audioQueuePlayer.nowPlayingQueue.count > 1 {
                        TutorialManager.instance.presentTutorialIfUnfulfilled(.DragToRearrange)
                    }
                }
            } else {
                TutorialManager.instance.dismissTutorial(.DragToRearrange, action: .DismissUnfulfilled)
                tableView.tableFooterView = nil
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
    
	
	//MARK: - Multi Select Toolbar Buttons
    private lazy var addToButton:UIBarButtonItem = UIBarButtonItem(title: "ADD TO PLAYLIST",
                                                                   style: .Plain,
	                                                               target: self,
	                                                               action: #selector(self.addSelectedToPlaylist))
    
	private lazy var selectAllButton:UIBarButtonItem = UIBarButtonItem(title: KyoozConstants.selectAllString.uppercaseString,
	                                                                   style: .Plain,
	                                                                   target: self,
	                                                                   action: #selector(self.selectOrDeselectAll))
    
    private lazy var deleteButton:UIBarButtonItem = UIBarButtonItem(title: "REMOVE",
                                                                    style: .Plain,
                                                                    target: self,
                                                                    action: #selector(self.deleteSelectedIndexPaths))
    
    //MARK: - Header Buttons
    private lazy var clearQueueButton:UIBarButtonItem = UIBarButtonItem(title: "CLEAR QUEUE",
                                                                        style: .Plain,
                                                                        target: self,
                                                                        action: #selector(self.deleteWholeQueue))
    
    private lazy var addQueueToPlaylistButton:UIBarButtonItem = UIBarButtonItem(title: "ADD TO PLAYLIST",
                                                                                style: .Plain,
                                                                                target: self,
                                                                                action: #selector(self.addWholeQueueToPlaylist))
    
    private lazy var selectButton:MultiSelectButtonView = {
        let s = MultiSelectButtonView(frame:CGRect(origin: CGPoint.zero, size: CGSize(width: 40, height: 40)))
        s.addTarget(self, action: #selector(self.toggleSelectMode), forControlEvents: .TouchUpInside)
        return s
    }()
    
    private lazy var standardToolbarItems:[UIBarButtonItem] = [UIBarButtonItem.flexibleSpace(),
                                                               self.addQueueToPlaylistButton,
                                                               UIBarButtonItem.flexibleSpace(),
                                                               self.clearQueueButton,
                                                               UIBarButtonItem.flexibleSpace()]
    private lazy var editingToolbarItems:[UIBarButtonItem] = {
        let items = [self.addToButton,
                     UIBarButtonItem.flexibleSpace(),
                     self.deleteButton,
                     UIBarButtonItem.flexibleSpace(),
                     self.selectAllButton]
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(self.refreshButtonStates),
                                                         name: UITableViewSelectionDidChangeNotification,
                                                         object: self.tableView)
        return items
    }()
    
    private let headerView = PlainHeaderView()
    
    //MARK: GESTURE PROPERTIES
    private var dragToRearrangeGestureHandler:LongPressToDragGestureHandler!
    var insertMode:Bool = false {
        didSet {
            longPressGestureRecognizer.enabled = !insertMode
            toolbarItems?.forEach() { $0.enabled = !insertMode }
			if !insertMode {
				//removing the footer view improves the animation for items inserted from drag and drop
				tableView.tableFooterView = nil
			}
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
        
        title = "QUEUE"
        
        ConstraintUtils.applyStandardConstraintsToView(subView: tableView, parentView: view)
        tableView.rowHeight = ThemeHelper.sidePanelTableViewRowHeight
        tableView.registerNib(NibContainer.songTableViewCellNib, forCellReuseIdentifier: "songDetailsTableViewCell")
        tableView.scrollsToTop = isExpanded
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.showsVerticalScrollIndicator = true
        tableView.indicatorStyle = .White
		
		let headerView = self.headerView
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Top, .Left, .Right], subView: headerView, parentView: view)
        headerView.bottomAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor).active = true
		tableView.contentOffset.y = -tableView.contentInset.top

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView:selectButton)
		
        dragToRearrangeGestureHandler = LongPressToDragGestureHandler(tableView: tableView)
        dragToRearrangeGestureHandler.delegate = self
		longPressGestureRecognizer = UILongPressGestureRecognizer(target: dragToRearrangeGestureHandler,
		                                                          action: #selector(LongPressToDragGestureHandler.handleGesture(_:)))
        tableView.addGestureRecognizer(longPressGestureRecognizer)
        navigationController?.toolbarHidden = false
        toolbarItems = standardToolbarItems
        
        resetDSD()
        registerForNotifications()

    }
	
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        laidOutSubviews = true
    }
	

    private func resetDSD() {
        datasourceDelegate = NowPlayingQueueDSD(reuseIdentifier: SongDetailsTableViewCell.reuseIdentifier, audioCellDelegate: self)
    }

    //MARK: INSERT MODE FUNCITONS
    func setDropItems(dropItems: [AudioTrack], atIndex index:NSIndexPath) -> Int {
        return audioQueuePlayer.insert(tracks: dropItems, at: index.row)
    }
    
    func gestureDidEnd(sender: UIGestureRecognizer) {
        resetDSD()
        TutorialManager.instance.dismissTutorial(.DragToRearrange, action: .Fulfill)
    }

    //MARK: CLASS Functions
    func reloadTableData() {
        tableView.reloadData()
        
        let queueNotEmpty = !audioQueuePlayer.nowPlayingQueue.isEmpty
        clearQueueButton.enabled = queueNotEmpty
        addQueueToPlaylistButton.enabled = queueNotEmpty
        selectButton.enabled = queueNotEmpty
        
        if !queueNotEmpty && tableView.editing {
            toggleSelectMode()
        }
		if isExpanded {
			refreshTableFooter()
		}
    }
	
	func refreshTableFooter() {
		let queue = audioQueuePlayer.nowPlayingQueue
		let count = queue.count
        
        let duration:NSTimeInterval = queue.reduce(0) { return $0 + $1.playbackDuration }
        
		let albumDurationString = MediaItemUtils.getLongTimeRepresentation(duration)?.uppercaseString
		tableFooterView.text = "\(count) TRACK\(count == 1 ? "" : "S")\n\(albumDurationString ?? "")"
		tableView.tableFooterView = tableFooterView
	}
	
    //for data source updates originating from the UI, we dont want to reload the table view in response to the queue changes
    //because there should already be animations taking place to reflect that content and reloading the data will interfere 
    //with the visual effect
    func reloadIfCollapsed() {
        if !isExpanded {
            reloadTableData()
		} else {
			refreshTableFooter()
		}
    }
    
    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(self.reloadTableData),
            name: AudioQueuePlayerUpdate.nowPlayingItemChanged.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(self.reloadTableData),
            name: AudioQueuePlayerUpdate.playbackStateUpdate.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(self.reloadTableData),
            name: AudioQueuePlayerUpdate.systematicQueueUpdate.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(self.reloadIfCollapsed),
            name: AudioQueuePlayerUpdate.queueUpdate.rawValue, object: audioQueuePlayer)
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
            tableView.reloadSections(NSIndexSet(index:0), withRowAnimation: .Automatic)
        }
    }
	
	//MARK: - Header view functions
	
	func addWholeQueueToPlaylist() {
		let queue = audioQueuePlayer.nowPlayingQueue
		guard !queue.isEmpty else { return }
		Playlists.showAvailablePlaylists(forAddingTracks: queue, usingTitle: "ADD QUEUE TO PLAYLIST")
	}
	
	func deleteWholeQueue() {
		func delete() {
			audioQueuePlayer.clear(from: .bothDirections, at: audioQueuePlayer.indexOfNowPlayingItem)
            tableView.reloadSections(NSIndexSet(index:0), withRowAnimation: .Automatic)
		}
		
		guard !audioQueuePlayer.nowPlayingQueue.isEmpty else { return }
		KyoozUtils.confirmAction("Clear the entire queue?", action: delete)
	}
		
    func presentActionsForCell(cell:UITableViewCell, title: String?, details: String?, originatingCenter:CGPoint) {
        guard !tableView.editing  else { return }
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
        
        var jumpToActions = [KyoozOption]()
        if mediaItem.albumId != 0 {
			let goToAlbumAction = KyoozMenuAction(title: KyoozConstants.JUMP_TO_ALBUM) {
                ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(MediaQuerySourceData(filterEntity: mediaItem, parentLibraryGroup: LibraryGrouping.Albums, baseQuery: nil)!,
                    parentGroup: LibraryGrouping.Albums, entity: mediaItem)
            }
            jumpToActions.append(goToAlbumAction)
        }
        
        if mediaItem.albumArtistId != 0 {
            let goToArtistAction = KyoozMenuAction(title: KyoozConstants.JUMP_TO_ARTIST) {
                ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(MediaQuerySourceData(filterEntity: mediaItem, parentLibraryGroup: LibraryGrouping.Artists, baseQuery: nil)!, parentGroup: LibraryGrouping.Artists, entity: mediaItem)
            }
            jumpToActions.append(goToArtistAction)
        }
        menuVC.addActions(jumpToActions)
        
        var removeActions = [KyoozOption]()
        if (!audioQueuePlayer.musicIsPlaying || index <= indexOfNowPlayingItem) && index > 0 {
            let clearPrecedingItemsAction = KyoozMenuAction(title: "REMOVE ABOVE") {
                
                let indiciesToDelete = (0..<index).map { NSIndexPath(forRow: $0, inSection: 0) }
                
                KyoozUtils.confirmAction("Remove the \(indiciesToDelete.count) tracks Above?", actionDetails: "Selected Track: \(title ?? "" )\n\(details ?? "")") {
                    self.audioQueuePlayer.clear(from: .above, at: index)
                    self.deleteIndexPaths(indiciesToDelete)
                }
            }
            removeActions.append(clearPrecedingItemsAction)
        }
        
		let deleteAction = KyoozMenuAction(title: "REMOVE") {
            self.datasourceDelegate.tableView?(self.tableView, commitEditingStyle: .Delete,
                forRowAtIndexPath: indexPath)
        }
        removeActions.append(deleteAction)
        
        if((!audioQueuePlayer.musicIsPlaying || index >= indexOfNowPlayingItem) && (index < lastIndex)) {
			let clearUpcomingItemsAction = KyoozMenuAction(title: "REMOVE BELOW") {
                
                let indiciesToDelete = ((index + 1)...lastIndex).map { NSIndexPath(forRow: $0, inSection: 0) }
                
                KyoozUtils.confirmAction("Remove the \(indiciesToDelete.count) tracks Below?", actionDetails: "Selected Track: \(title ?? "")\n\(details ?? "")") {
                    self.audioQueuePlayer.clear(from: .below, at: index)
                    self.deleteIndexPaths(indiciesToDelete)
                }
            }
            removeActions.append(clearUpcomingItemsAction)
        }
        menuVC.addActions(removeActions)
        menuVC.addActions([KyoozMenuAction(title: KyoozConstants.ADD_TO_PLAYLIST, image: nil) {
            Playlists.showAvailablePlaylists(forAddingTracks: [mediaItem])
        }])
		menuVC.originatingCenter = originatingCenter
		
		KyoozUtils.showMenuViewController(menuVC)
    }

}

//MARK: - Multi Select Functions
extension NowPlayingQueueViewController {
	
	func toggleSelectMode() {
		let willEdit = !tableView.editing
		
		tableView.setEditing(willEdit, animated: true)
		longPressGestureRecognizer.enabled = !willEdit
		
        setToolbarItems(willEdit ? editingToolbarItems : standardToolbarItems, animated: true)
		selectButton.isActive = willEdit
        
		refreshButtonStates()
	}
	
	func addSelectedToPlaylist() {
		guard let tracks = getOrderedTracks() where tableView.editing else { return }

        Playlists.showAvailablePlaylists(forAddingTracks:tracks,
                                          usingTitle: "ADD \(tracks.count) TRACKS TO PLAYLIST",
                                          completionAction:toggleSelectMode)
    }
	
	
	func refreshButtonStates() {
		let isNotEmpty = tableView.indexPathsForSelectedRows != nil
		
		deleteButton.enabled = isNotEmpty
		addToButton.enabled = isNotEmpty
		selectAllButton.title = isNotEmpty ? KyoozConstants.deselectAllString : KyoozConstants.selectAllString
	}
	
	func selectOrDeselectAll() {
		tableView.selectOrDeselectAll()
		refreshButtonStates()
	}
	
	private func getOrderedTracks() -> [AudioTrack]? {
        let queue = audioQueuePlayer.nowPlayingQueue
		return tableView.indexPathsForSelectedRows?.sort(<).map() { return queue[$0.row] }
	}
	
	func deleteSelectedIndexPaths() {
		func delete(indexPathsToDelete:[NSIndexPath]) {
            audioQueuePlayer.delete(at: indexPathsToDelete.map { $0.row })
			deleteIndexPaths(indexPathsToDelete)
		}
		guard let indexPathsToDelete = tableView.indexPathsForSelectedRows where tableView.editing else {
			return
		}
		
		KyoozUtils.confirmAction("Remove the \(indexPathsToDelete.count) selected tracks?") {
			delete(indexPathsToDelete)
		}
	}
	
	
}

