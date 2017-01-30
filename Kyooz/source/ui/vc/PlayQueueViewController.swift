//
//  NowPlayingQueueViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class PlayQueueViewController: UIViewController, DropDestination, AudioTableCellDelegate, GestureHandlerDelegate {

    static let instance = PlayQueueViewController()
    
    fileprivate let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    fileprivate let tableFooterView = KyoozTableFooterView()
    fileprivate var longPressGestureRecognizer:UILongPressGestureRecognizer!
    
    fileprivate (set) var laidOutSubviews:Bool = false
    fileprivate var multipleDeleteButton:UIBarButtonItem!
	
	var shouldAnimateInArtwork: Bool { return false }
    var menuButtonTouched:Bool = false
    var isExpanded:Bool = false {
        didSet {
            if isExpanded {
                reloadTableData()
                KyoozUtils.doInMainQueueAfterDelay(0.5) {
                    if !self.insertMode && self.audioQueuePlayer.nowPlayingQueue.count > 1 {
                        TutorialManager.instance.presentTutorialIfUnfulfilled(.dragToRearrange)
                    }
                }
            } else {
                TutorialManager.instance.dismissTutorial(.dragToRearrange, action: .dismissUnfulfilled)
                tableView.tableFooterView = nil
                if tableView.isEditing {
                    toggleSelectMode()
                }
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
    fileprivate lazy var addToButton:UIBarButtonItem = UIBarButtonItem(title: "ADD TO PLAYLIST",
                                                                   style: .plain,
	                                                               target: self,
	                                                               action: #selector(self.addSelectedToPlaylist))
    
	fileprivate lazy var selectAllButton:UIBarButtonItem = UIBarButtonItem(title: KyoozConstants.selectAllString.uppercased(),
	                                                                   style: .plain,
	                                                                   target: self,
	                                                                   action: #selector(self.selectOrDeselectAll))
    
    fileprivate lazy var deleteButton:UIBarButtonItem = UIBarButtonItem(title: "REMOVE",
                                                                    style: .plain,
                                                                    target: self,
                                                                    action: #selector(self.deleteSelectedIndexPaths))
    
    //MARK: - Header Buttons
    fileprivate lazy var clearQueueButton:UIBarButtonItem = UIBarButtonItem(title: "CLEAR QUEUE",
                                                                        style: .plain,
                                                                        target: self,
                                                                        action: #selector(self.deleteWholeQueue))
    
    fileprivate lazy var addQueueToPlaylistButton:UIBarButtonItem = UIBarButtonItem(title: "ADD TO PLAYLIST",
                                                                                style: .plain,
                                                                                target: self,
                                                                                action: #selector(self.addWholeQueueToPlaylist))
    
    fileprivate lazy var selectButton:MultiSelectButtonView = {
        let s = MultiSelectButtonView(frame:CGRect(origin: CGPoint.zero, size: CGSize(width: 40, height: 40)))
        s.addTarget(self, action: #selector(self.toggleSelectMode), for: .touchUpInside)
        return s
    }()
    
    fileprivate lazy var standardToolbarItems:[UIBarButtonItem] = [UIBarButtonItem.flexibleSpace(),
                                                               self.addQueueToPlaylistButton,
                                                               UIBarButtonItem.flexibleSpace(),
                                                               self.clearQueueButton,
                                                               UIBarButtonItem.flexibleSpace()]
    fileprivate lazy var editingToolbarItems:[UIBarButtonItem] = {
        let items = [self.addToButton,
                     UIBarButtonItem.flexibleSpace(),
                     self.deleteButton,
                     UIBarButtonItem.flexibleSpace(),
                     self.selectAllButton]
        
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(self.refreshButtonStates),
                                                         name: NSNotification.Name.UITableViewSelectionDidChange,
                                                         object: self.tableView)
        return items
    }()
    
    fileprivate let headerView = PlainHeaderView()
    
    //MARK: GESTURE PROPERTIES
    fileprivate var dragToRearrangeGestureHandler:LongPressToDragGestureHandler!
    var insertMode:Bool = false {
        didSet {
            longPressGestureRecognizer.isEnabled = !insertMode
            toolbarItems?.forEach() { $0.isEnabled = !insertMode }
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
        tableView.register(NibContainer.songTableViewCellNib, forCellReuseIdentifier: "songDetailsTableViewCell")
        tableView.scrollsToTop = isExpanded
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.showsVerticalScrollIndicator = true
        tableView.indicatorStyle = .white
        tableView.isAccessibilityElement = true
        tableView.accessibilityIdentifier = "playQueue"
		
		let headerView = self.headerView
        ConstraintUtils.applyConstraintsToView(withAnchors: [.top, .left, .right], subView: headerView, parentView: view)
        headerView.bottomAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
		tableView.contentOffset.y = -tableView.contentInset.top

        let selectButton = UIBarButtonItem(customView:self.selectButton)
        selectButton.isAccessibilityElement = true
        selectButton.accessibilityLabel = "playQueueSelectButton"
        navigationItem.rightBarButtonItem = selectButton
		
        dragToRearrangeGestureHandler = LongPressToDragGestureHandler(tableView: tableView)
        dragToRearrangeGestureHandler.delegate = self
		longPressGestureRecognizer = UILongPressGestureRecognizer(target: dragToRearrangeGestureHandler,
		                                                          action: #selector(LongPressToDragGestureHandler.handleGesture(_:)))
        tableView.addGestureRecognizer(longPressGestureRecognizer)
        navigationController?.isToolbarHidden = false
        toolbarItems = standardToolbarItems
        
        resetDSD()
        registerForNotifications()

    }
	
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        laidOutSubviews = true
    }
	

    fileprivate func resetDSD() {
        datasourceDelegate = NowPlayingQueueDSD(reuseIdentifier: SongDetailsTableViewCell.reuseIdentifier, audioCellDelegate: self)
    }

    //MARK: INSERT MODE FUNCITONS
    func setDropItems(_ dropItems: [AudioTrack], atIndex index:IndexPath) -> Int {
        return audioQueuePlayer.insert(tracks: dropItems, at: (index as NSIndexPath).row)
    }
    
    func gestureDidEnd(_ sender: UIGestureRecognizer) {
        resetDSD()
        TutorialManager.instance.dismissTutorial(.dragToRearrange, action: .fulfill)
    }

    //MARK: CLASS Functions
    func reloadTableData() {
        tableView.reloadData()
        
        let queueNotEmpty = !audioQueuePlayer.nowPlayingQueue.isEmpty
        clearQueueButton.isEnabled = queueNotEmpty
        addQueueToPlaylistButton.isEnabled = queueNotEmpty
        selectButton.isEnabled = queueNotEmpty
        
        if !queueNotEmpty && tableView.isEditing {
            toggleSelectMode()
        }
		if isExpanded {
			refreshTableFooter()
		}
    }
	
	func refreshTableFooter() {
		let queue = audioQueuePlayer.nowPlayingQueue
		let count = queue.count
        
        let duration:TimeInterval = queue.reduce(0) { return $0 + $1.playbackDuration }
        
		let albumDurationString = MediaItemUtils.getLongTimeRepresentation(duration)?.uppercased()
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
    
    fileprivate func registerForNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(self.reloadTableData),
            name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.nowPlayingItemChanged.rawValue), object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(self.reloadTableData),
            name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.playbackStateUpdate.rawValue), object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(self.reloadTableData),
            name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.systematicQueueUpdate.rawValue), object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(self.reloadIfCollapsed),
            name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.queueUpdate.rawValue), object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(self.reloadTableData),
            name: NSNotification.Name.UIApplicationDidBecomeActive, object: UIApplication.shared)
    }
    
    fileprivate func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func deleteIndexPaths(_ indiciesToDelete:[IndexPath]) {
        if indiciesToDelete.isEmpty { return }
        
        if indiciesToDelete.count < 250 {
            tableView.deleteRows(at: indiciesToDelete, with: .automatic)
        } else {
            tableView.reloadSections(IndexSet(integer:0), with: .automatic)
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
            tableView.reloadSections(IndexSet(integer:0), with: .automatic)
		}
		
		guard !audioQueuePlayer.nowPlayingQueue.isEmpty else { return }
		KyoozUtils.confirmAction("Clear the entire queue?", action: delete)
	}
		
    func presentActionsForCell(_ cell:UITableViewCell, title: String?, details: String?, originatingCenter:CGPoint) {
        guard !tableView.isEditing  else { return }
        guard let indexPath = tableView.indexPath(for: cell) else {
            Logger.error("no index path found for cell with tile \(title)")
            return
        }
        let index = (indexPath as NSIndexPath).row
        let mediaItem = audioQueuePlayer.nowPlayingQueue[index]
        
        let menuBuilder = MenuBuilder()
            .with(title: title)
            .with(details: details)

        
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
        menuBuilder.with(options: jumpToActions)
        
        var removeActions = [KyoozOption]()
        if (!audioQueuePlayer.musicIsPlaying || index <= indexOfNowPlayingItem) && index > 0 {
            let clearPrecedingItemsAction = KyoozMenuAction(title: "REMOVE ABOVE") {
                
                let indiciesToDelete = (0..<index).map { IndexPath(row: $0, section: 0) }
                
                KyoozUtils.confirmAction("Remove the \(indiciesToDelete.count) tracks Above?", actionDetails: "Selected Track: \(title ?? "" )\n\(details ?? "")") {
                    self.audioQueuePlayer.clear(from: .above, at: index)
                    self.deleteIndexPaths(indiciesToDelete)
                }
            }
            removeActions.append(clearPrecedingItemsAction)
        }
        
		let deleteAction = KyoozMenuAction(title: "REMOVE") {
            self.datasourceDelegate.tableView?(self.tableView, commit: .delete,
                forRowAt: indexPath)
        }
        removeActions.append(deleteAction)
        
        if((!audioQueuePlayer.musicIsPlaying || index >= indexOfNowPlayingItem) && (index < lastIndex)) {
			let clearUpcomingItemsAction = KyoozMenuAction(title: "REMOVE BELOW") {
                
                let indiciesToDelete = ((index + 1)...lastIndex).map { IndexPath(row: $0, section: 0) }
                
                KyoozUtils.confirmAction("Remove the \(indiciesToDelete.count) tracks Below?", actionDetails: "Selected Track: \(title ?? "")\n\(details ?? "")") {
                    self.audioQueuePlayer.clear(from: .below, at: index)
                    self.deleteIndexPaths(indiciesToDelete)
                }
            }
            removeActions.append(clearUpcomingItemsAction)
        }
        menuBuilder.with(options: removeActions)
        menuBuilder.with(options: KyoozMenuAction(title: KyoozConstants.ADD_TO_PLAYLIST) {
            Playlists.showAvailablePlaylists(forAddingTracks: [mediaItem])
        })
		menuBuilder.with(originatingCenter: originatingCenter)
		
		KyoozUtils.showMenuViewController(menuBuilder.viewController)
    }

}

//MARK: - Multi Select Functions
extension PlayQueueViewController {
	
	func toggleSelectMode() {
		let willEdit = !tableView.isEditing
		
		tableView.setEditing(willEdit, animated: true)
		longPressGestureRecognizer.isEnabled = !willEdit
		
        setToolbarItems(willEdit ? editingToolbarItems : standardToolbarItems, animated: true)
		selectButton.isActive = willEdit
        
		refreshButtonStates()
	}
	
	func addSelectedToPlaylist() {
		guard let tracks = getOrderedTracks(), tableView.isEditing else { return }

        Playlists.showAvailablePlaylists(forAddingTracks:tracks,
                                          usingTitle: "ADD \(tracks.count) TRACKS TO PLAYLIST",
                                          completionAction:toggleSelectMode)
    }
	
	
	func refreshButtonStates() {
		let isNotEmpty = tableView.indexPathsForSelectedRows != nil
		
		deleteButton.isEnabled = isNotEmpty
		addToButton.isEnabled = isNotEmpty
		selectAllButton.title = isNotEmpty ? KyoozConstants.deselectAllString : KyoozConstants.selectAllString
	}
	
	func selectOrDeselectAll() {
		tableView.selectOrDeselectAll()
		refreshButtonStates()
	}
	
	fileprivate func getOrderedTracks() -> [AudioTrack]? {
        let queue = audioQueuePlayer.nowPlayingQueue
		return tableView.indexPathsForSelectedRows?.sorted(by: <).map() { return queue[($0 as NSIndexPath).row] }
	}
	
	func deleteSelectedIndexPaths() {
		func delete(_ indexPathsToDelete:[IndexPath]) {
            audioQueuePlayer.delete(at: indexPathsToDelete.map { ($0 as NSIndexPath).row })
			deleteIndexPaths(indexPathsToDelete)
		}
		guard let indexPathsToDelete = tableView.indexPathsForSelectedRows, tableView.isEditing else {
			return
		}
		
		KyoozUtils.confirmAction("Remove the \(indexPathsToDelete.count) selected tracks?") {
			delete(indexPathsToDelete)
		}
	}
	
	
}

