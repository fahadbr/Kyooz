//
//  AudioEntityViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/3/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class AudioEntityHeaderViewController<DSD: AudioEntityDSDProtocol> : AudioEntityViewController<DSD>, UIScrollViewDelegate {

	
	var headerHeightConstraint: NSLayoutConstraint!
	var maxHeight:CGFloat!
	var minHeight:CGFloat!
	var collapsedTargetOffset:CGFloat!
	
	var useCollapsableHeader:Bool = false
	private var headerCollapsed:Bool = false
	
    private lazy var headerVC:HeaderViewController = self.createHeaderView()
	
	//MARK: - Multi Select Toolbar Buttons
    private lazy var addToButton:UIBarButtonItem = UIBarButtonItem(title: "ADD TO..",
                                                                   style: .Plain,
	                                                               target: self,
	                                                               action: #selector(self.showAddToOptions(_:)))
    
    
	private lazy var selectAllButton:UIBarButtonItem = UIBarButtonItem(title: KyoozConstants.selectAllString,
	                                                                   style: .Plain,
	                                                                   target: self,
	                                                                   action: #selector(self.selectOrDeselectAll))
    
    private lazy var deleteButton:UIBarButtonItem = UIBarButtonItem(title: "REMOVE",
                                                                    style: .Plain,
	                                                                target: self,
	                                                                action: #selector(self.deleteSelectedItems))
    
    private lazy var playButton:UIBarButtonItem = UIBarButtonItem(title: "PLAY",
                                                                  style: .Plain,
                                                                  target: self,
                                                                  action: #selector(self.playSelectedTracks(_:)))
    
    private lazy var shuffleToolbarButton:UIBarButtonItem = UIBarButtonItem(title: "SHUFFLE",
                                                                            style: .Plain,
                                                                            target: self,
                                                                            action: #selector(self.playSelectedTracks(_:)))
    
    //MARK: - View Lifecycle Functions
	
	override func viewDidLoad() {
        super.viewDidLoad()
		automaticallyAdjustsScrollViewInsets = false
		view.backgroundColor = ThemeHelper.defaultTableCellColor
		
		ConstraintUtils.applyConstraintsToView(withAnchors: [.Top, .Left, .Right], subView: headerVC.view, parentView: view)
		headerHeightConstraint = headerVC.view.heightAnchor.constraintEqualToConstant(headerVC.defaultHeight)
		headerHeightConstraint.active = true
		
        addChildViewController(headerVC)
        headerVC.didMoveToParentViewController(self)
		
		headerVC.leftButton.addTarget(self, action: #selector(self.shuffleAllItems(_:)), forControlEvents: .TouchUpInside)
		headerVC.selectButton.addTarget(self, action: #selector(self.toggleSelectMode), forControlEvents: .TouchUpInside)
		
		minHeight = headerVC.minimumHeight
		maxHeight = headerVC.defaultHeight
		collapsedTargetOffset = maxHeight - minHeight
		tableView.contentInset.top = minHeight
        tableView.scrollIndicatorInsets.top = maxHeight
        tableView.contentOffset.y = -tableView.contentInset.top
        
        tableView.panGestureRecognizer.requireGestureRecognizerToFail(popGestureRecognizer)
        tableView.panGestureRecognizer.requireGestureRecognizerToFail(ContainerViewController.instance.centerPanelPanGestureRecognizer)

		if useCollapsableHeader {
			tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: collapsedTargetOffset))
			view.addGestureRecognizer(tableView.panGestureRecognizer)
		}
	}
    
    func createHeaderView() -> HeaderViewController {
        let centerVC:UIViewController = HeaderLabelStackController(sourceData: sourceData)
        return self.useCollapsableHeader ? ArtworkHeaderViewController(centerViewController:centerVC) : UtilHeaderViewController(centerViewController:centerVC)
    }
	
	//MARK: - Scroll View Delegate
	final func scrollViewDidScroll(scrollView: UIScrollView) {
		if !useCollapsableHeader { return }
		let currentOffset = scrollView.contentOffset.y + scrollView.contentInset.top
		
		if  currentOffset < collapsedTargetOffset {
			headerHeightConstraint.constant = (maxHeight - currentOffset)
			scrollView.scrollIndicatorInsets.top = collapsedTargetOffset - scrollView.contentOffset.y
			headerCollapsed = false
		} else if !headerCollapsed {
			headerHeightConstraint.constant = minHeight
			scrollView.scrollIndicatorInsets.top = minHeight
			headerCollapsed = true
		}
	}
    
    override func reloadTableViewData() {
        if !tableView.editing {
            super.reloadTableViewData()
        }
    }
    
    override func registerForNotifications() {
        super.registerForNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(self.refreshButtonStates),
                                                         name: UITableViewSelectionDidChangeNotification,
                                                         object: tableView)
    }
	
//	
//}
//
////MARK: - Multi Select Functions
//extension AudioEntityHeaderViewController {
	
	
	func toggleSelectMode() {
		let willEdit = !tableView.editing
		
		tableView.setEditing(willEdit, animated: true)
        navigationController?.setToolbarHidden(!willEdit, animated: true)
		
		if willEdit && toolbarItems == nil {
			
			var toolbarItems = [playButton,
			                    UIBarButtonItem.flexibleSpace(),
			                    shuffleToolbarButton,
			                    UIBarButtonItem.flexibleSpace(),
			                    addToButton,
			                    UIBarButtonItem.flexibleSpace(),
			                    selectAllButton]

            
            if sourceData is MutableAudioEntitySourceData {
                toolbarItems.insertContentsOf([UIBarButtonItem.flexibleSpace(), deleteButton], at: 5)
            }

			self.toolbarItems = toolbarItems
		}
        
        headerVC.selectButton.isActive = willEdit
		
		refreshButtonStates()
	}
	
	func shuffleAllItems(sender:UIButton?) {
		playAllItems(sender, shouldShuffle: true)
	}
	
	private func playAllItems(sender:UIButton?, shouldShuffle:Bool) {
        let items = sourceData.tracks
		if !items.isEmpty {
			self.playTracks(items, shouldShuffle: shouldShuffle)
		}
	}
	
	private func playTracks(tracks:[AudioTrack], shouldShuffle:Bool) {
		audioQueuePlayer.playNow(withTracks: tracks,
		                         startingAtIndex: shouldShuffle ? KyoozUtils.randomNumber(belowValue: tracks.count):0,
		                         shouldShuffleIfOff: shouldShuffle)
	}
	
	
	func refreshButtonStates() {
        guard tableView.editing else { return }
        
		let isNotEmpty = tableView.indexPathsForSelectedRows != nil
		
		playButton.enabled = isNotEmpty
        deleteButton.enabled = isNotEmpty
		addToButton.enabled = isNotEmpty
		shuffleToolbarButton.enabled = isNotEmpty
		selectAllButton.title = isNotEmpty ? KyoozConstants.deselectAllString : KyoozConstants.selectAllString
	}
	
	func selectOrDeselectAll() {
		tableView.selectOrDeselectAll()
		refreshButtonStates()
	}
	
	private func getOrderedTracks() -> [AudioTrack]? {
        return tableView.indexPathsForSelectedRows?.sort(<).flatMap() { self.sourceData.getTracksAtIndex($0) }
	}
	
	func playSelectedTracks(sender:AnyObject!) {
		guard let tracks = getOrderedTracks() else { return }
		
		playTracks(tracks, shouldShuffle: (sender != nil && sender is ShuffleButtonView))
		
		selectOrDeselectAll()
		toggleSelectMode()
	}
	
	func showAddToOptions(sender:UIBarButtonItem!) {
		guard let items = getOrderedTracks() else { return }
		let kmvc = KyoozMenuViewController()
		kmvc.menuTitle = "\(tableView.indexPathsForSelectedRows?.count ?? 0) Selected Items"
		KyoozUtils.addDefaultQueueingActions(items, menuController: kmvc) {
			self.toggleSelectMode()
		}
		
		KyoozUtils.showMenuViewController(kmvc)
	}
	
	
	func deleteSelectedItems() {
		
		func deleteInternal() {
			guard let mutableSourceData = self.sourceData as? MutableAudioEntitySourceData,
                let selectedIndicies = tableView.indexPathsForSelectedRows else {
				return
			}
			do {
				try mutableSourceData.deleteEntitiesAtIndexPaths(selectedIndicies)
				tableView.deleteRowsAtIndexPaths(selectedIndicies, withRowAnimation: .Automatic)
				refreshButtonStates()
			} catch let error {
				KyoozUtils.showPopupError(withTitle: "Error occured while deleting items", withThrownError: error, presentationVC: nil)
			}
		}
		
        KyoozUtils.confirmAction("Delete \(tableView.indexPathsForSelectedRows?.count ?? 0) Selected Items?", action: deleteInternal)
	}
	
}

