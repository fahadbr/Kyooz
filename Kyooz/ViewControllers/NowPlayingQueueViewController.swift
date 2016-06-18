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
	private lazy var addToButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem:.Add, target: self, action: #selector(self.addSelectedToPlaylist))
	private lazy var selectAllButton:UIBarButtonItem = UIBarButtonItem(title: KyoozConstants.selectAllString, style: .Plain, target: self, action: #selector(self.selectOrDeselectAll))
	private lazy var deleteButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(self.deleteSelectedIndexPaths))
    
    //MARK: - Header Buttons
    private lazy var headerDeleteButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(self.deleteWholeQueue))
    private lazy var headerAddToButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(self.addWholeQueueToPlaylist))
    private lazy var headerViewController:HeaderViewController = {
        let hToolbar = UIToolbar()
        hToolbar.setBackgroundImage(UIImage(), forToolbarPosition: .Any, barMetrics: .Default)
        hToolbar.setShadowImage(UIImage(), forToolbarPosition: .Any)
        hToolbar.userInteractionEnabled = true
        let space = { return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil) }
        hToolbar.items = [space(), self.headerAddToButton, space(), self.headerDeleteButton, space()]
        
        return UtilHeaderViewController(centerViewController: GenericWrapperViewController(viewToWrap: hToolbar))
    }()
    
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
        automaticallyAdjustsScrollViewInsets = false
        tableView.rowHeight = ThemeHelper.sidePanelTableViewRowHeight
        tableView.registerNib(NibContainer.songTableViewCellNib, forCellReuseIdentifier: "songDetailsTableViewCell")
        tableView.scrollsToTop = isExpanded
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.showsVerticalScrollIndicator = true
        tableView.indicatorStyle = .White
		
		let headerView = headerViewController.view
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Top, .Left, .Right], subView: headerView, parentView: view)
        headerView.heightAnchor.constraintEqualToConstant(headerViewController.defaultHeight).active = true
		tableView.contentInset.top = headerViewController.defaultHeight
		tableView.scrollIndicatorInsets.top = headerViewController.defaultHeight
		tableView.contentOffset.y = -tableView.contentInset.top

		
		headerViewController.selectButton.addTarget(self, action: #selector(self.toggleSelectMode), forControlEvents: .TouchUpInside)
		headerViewController.leftButton.addTarget(self, action: #selector(self.toggleShuffle), forControlEvents: .TouchUpInside)
		
        dragToRearrangeGestureHandler = LongPressToDragGestureHandler(tableView: tableView)
        dragToRearrangeGestureHandler.delegate = self
		longPressGestureRecognizer = UILongPressGestureRecognizer(target: dragToRearrangeGestureHandler,
		                                                          action: #selector(LongPressToDragGestureHandler.handleGesture(_:)))
        tableView.addGestureRecognizer(longPressGestureRecognizer)
        
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
    func setDropItems(dropItems: [AudioTrack], atIndex:NSIndexPath) -> Int {
        return audioQueuePlayer.insertItemsAtIndex(dropItems, index: atIndex.row)
    }
    
    func gestureDidEnd(sender: UIGestureRecognizer) {
        resetDSD()
        TutorialManager.instance.dismissTutorial(.DragToRearrange, action: .Fulfill)
    }

    //MARK: CLASS Functions
    func reloadTableData() {
        tableView.reloadData()
		(headerViewController.leftButton as? ShuffleButtonView)?.isActive = audioQueuePlayer.shuffleActive
        let queueNotEmpty = !audioQueuePlayer.nowPlayingQueue.isEmpty
        headerDeleteButton.enabled = queueNotEmpty
        headerAddToButton.enabled = queueNotEmpty
        headerViewController.leftButton.enabled = queueNotEmpty
        headerViewController.selectButton.enabled = queueNotEmpty
		if isExpanded {
			refreshTableFooter()
		}
    }
	
	func refreshTableFooter() {
		let queue = audioQueuePlayer.nowPlayingQueue
		let count = queue.count
		var duration:NSTimeInterval = 0
		for item in queue {
			duration += item.playbackDuration
		}
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
	
	//MARK: - Header view functions
	func toggleShuffle() {
		let shuffleActive = !audioQueuePlayer.shuffleActive
		audioQueuePlayer.shuffleActive = shuffleActive
		(headerViewController.leftButton as? ShuffleButtonView)?.isActive = shuffleActive
	}
	
	func addWholeQueueToPlaylist() {
		let queue = audioQueuePlayer.nowPlayingQueue
		guard !queue.isEmpty else { return }
		KyoozUtils.showAvailablePlaylists(forAddingTracks: queue, usingTitle: "ADD QUEUE TO PLAYLIST")
	}
	
	func deleteWholeQueue() {
		func delete() {
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
		
		guard !audioQueuePlayer.nowPlayingQueue.isEmpty else { return }
		KyoozUtils.confirmAction("Remove the entire queue?", action: delete)
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
            KyoozUtils.showAvailablePlaylists(forAddingTracks: [mediaItem])
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
		navigationController?.setToolbarHidden(!willEdit, animated: true)
		longPressGestureRecognizer.enabled = !willEdit
		
		if willEdit && toolbarItems == nil {
			func createFlexibleSpace() -> UIBarButtonItem {
				return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
			}
			
			let toolbarItems = [addToButton, createFlexibleSpace(), deleteButton, createFlexibleSpace(), selectAllButton]
			
			let tintColor = ThemeHelper.defaultTintColor
			toolbarItems.forEach() {
				$0.tintColor = tintColor
			}
			NSNotificationCenter.defaultCenter().addObserver(self,
			                                                 selector: #selector(self.refreshButtonStates),
			                                                 name: UITableViewSelectionDidChangeNotification,
			                                                 object: tableView)
			self.toolbarItems = toolbarItems
		}
		headerViewController.selectButton.isActive = willEdit
		headerViewController.leftButton.enabled = !willEdit
        headerDeleteButton.enabled = !willEdit
        headerAddToButton.enabled = !willEdit
        
		refreshButtonStates()
	}
	
	func addSelectedToPlaylist() {
		var tracks:[AudioTrack] = [AudioTrack]()
		let queue = audioQueuePlayer.nowPlayingQueue
		guard let indexPaths = tableView.indexPathsForSelectedRows where tableView.editing else { return }
		
		let indicies = indexPaths.map({$0.row}).sort(<)
		
		tracks.reserveCapacity(indicies.count)
		for i in indicies {
			tracks.append(queue[i])
		}
        KyoozUtils.showAvailablePlaylists(forAddingTracks:tracks, usingTitle: "ADD \(indicies.count) TRACKS TO PLAYLIST")
	}
	
	
	func refreshButtonStates() {
		let isNotEmpty = tableView.indexPathsForSelectedRows != nil
		
		deleteButton.enabled = isNotEmpty
		addToButton.enabled = isNotEmpty
		selectAllButton.title = isNotEmpty ? KyoozConstants.deselectAllString : KyoozConstants.selectAllString
	}
	
	func selectOrDeselectAll() {
		if let selectedIndicies = tableView.indexPathsForSelectedRows {
			for indexPath in selectedIndicies {
				tableView.deselectRowAtIndexPath(indexPath, animated: false)
			}
		} else {
			for section in 0 ..< tableView.numberOfSections {
				for row in 0 ..< tableView.numberOfRowsInSection(section) {
					let indexPath = NSIndexPath(forRow: row, inSection: section)
					tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
				}
			}
		}
		
		refreshButtonStates()
	}
	
	private func getOrderedTracks() -> [AudioTrack]? {
		guard var selectedIndicies = tableView.indexPathsForSelectedRows else { return nil }
		
		selectedIndicies.sortInPlace { (first, second) -> Bool in
			if first.section != second.section {
				return first.section < second.section
			}
			return first.row < second.row
		}
		
		let queue = audioQueuePlayer.nowPlayingQueue
		var items = [AudioTrack]()
		for indexPath in selectedIndicies {
			items.append(queue[indexPath.row])
		}
		return items
	}
	
	func deleteSelectedIndexPaths() {
		func delete(indexPathsToDelete:[NSIndexPath]) {
			let indicies = indexPathsToDelete.map() { $0.row }
			audioQueuePlayer.deleteItemsAtIndices(indicies)
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

