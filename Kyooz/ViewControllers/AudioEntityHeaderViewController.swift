//
//  AudioEntityViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/3/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class AudioEntityHeaderViewController : AudioEntityViewController, UIScrollViewDelegate {

	
	var headerHeightConstraint: NSLayoutConstraint!
	var maxHeight:CGFloat!
	var minHeight:CGFloat!
	var collapsedTargetOffset:CGFloat!
	
	var useCollapsableHeader:Bool = false
	private var headerCollapsed:Bool = false
	
    private lazy var headerVC:HeaderViewController = {
        switch (self.useCollapsableHeader, self.sourceData.parentGroup) {
        case (true, LibraryGrouping.Playlists?): break
        default: break
        }
        return HeaderViewController(centerViewController:SubGroupButtonController(subGroups:self.subGroups))
    }()
	
	//MARK: - Multi Select Toolbar Buttons
	private lazy var addToButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(self.showAddToOptions(_:)))
	private lazy var selectAllButton:UIBarButtonItem = UIBarButtonItem(title: KyoozConstants.selectAllString, style: .Plain, target: self, action: #selector(self.selectOrDeselectAll))
	private lazy var deleteButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(self.deleteSelectedItems))
	
	private lazy var playButton:UIBarButtonItem = {
		$0.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 40, height: 40))
		$0.isPlayButton = true
		$0.hasOuterFrame = false
		$0.color = ThemeHelper.defaultTintColor
		$0.addTarget(self, action: #selector(self.playSelectedTracks(_:)), forControlEvents: .TouchUpInside)
		return UIBarButtonItem(customView: $0)
	}(PlayPauseButtonView())
	
	private lazy var shuffleToolbarButton:UIBarButtonItem = {
		$0.color = ThemeHelper.defaultTintColor
		$0.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 40, height: 40))
		$0.addTarget(self, action: #selector(self.playSelectedTracks(_:)), forControlEvents: .TouchUpInside)
		return UIBarButtonItem(customView: $0)
	}(ShuffleButtonView())
	
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
		headerVC.selectButton.addTarget(self, action: #selector(self.toggleSelectMode(_:)), forControlEvents: .TouchUpInside)
		
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
	
	
}

//MARK: - Multi Select Functions
extension AudioEntityHeaderViewController {
	
	
	func toggleSelectMode(sender:UIButton?) {
		let willEdit = editing
		
		tableView.setEditing(willEdit, animated: true)
		RootViewController.instance.setToolbarHidden(!willEdit)
		
		if willEdit && toolbarItems == nil {
			func createFlexibleSpace() -> UIBarButtonItem {
				return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
			}
			
			var toolbarItems = [playButton, createFlexibleSpace(), shuffleToolbarButton, createFlexibleSpace(), addToButton]
			
			if sourceData is MutableAudioEntitySourceData {
				toolbarItems.append(createFlexibleSpace())
				toolbarItems.append(deleteButton)
			}
			toolbarItems.append(createFlexibleSpace())
			toolbarItems.append(selectAllButton)
			
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
		
		refreshButtonStates()
	}
	
	func shuffleAllItems(sender:UIButton?) {
		playAllItems(sender, shouldShuffle: true)
	}
	
	private func playAllItems(sender:UIButton?, shouldShuffle:Bool) {
		if let items = (sourceData as? MediaQuerySourceData)?.filterQuery.items where !items.isEmpty {
			self.playTracks(items, shouldShuffle: shouldShuffle)
		}
	}
	
	private func playTracks(tracks:[AudioTrack], shouldShuffle:Bool) {
		audioQueuePlayer.playNow(withTracks: tracks, startingAtIndex: shouldShuffle ? KyoozUtils.randomNumber(belowValue: tracks.count):0, shouldShuffleIfOff: shouldShuffle)
	}
	
	
	func refreshButtonStates() {
		let isNotEmpty = tableView.indexPathsForSelectedRows != nil
		
		playButton.enabled = isNotEmpty
		deleteButton.enabled = isNotEmpty
		addToButton.enabled = isNotEmpty
		shuffleToolbarButton.enabled = isNotEmpty
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
		
		var items = [AudioTrack]()
		for indexPath in selectedIndicies {
			items.appendContentsOf(sourceData.getTracksAtIndex(indexPath))
		}
		return items
	}
	
	func playSelectedTracks(sender:AnyObject!) {
		guard let tracks = getOrderedTracks() else { return }
		
		playTracks(tracks, shouldShuffle: (sender != nil && sender is ShuffleButtonView))
		
		selectOrDeselectAll()
		self.setEditing(false, animated: true)
	}
	
	func showAddToOptions(sender:UIBarButtonItem!) {
		guard let items = getOrderedTracks() else { return }
		let kmvc = KyoozMenuViewController()
		kmvc.menuTitle = "\(tableView.indexPathsForSelectedRows?.count ?? 0) Selected Items"
		KyoozUtils.addDefaultQueueingActions(items, menuController: kmvc) {
			self.selectOrDeselectAll()
			self.setEditing(false, animated: true)
		}
		
		KyoozUtils.showMenuViewController(kmvc)
	}
	
	
	func deleteSelectedItems() {
		
		func deleteInternal() {
			guard let mutableSourceData = self.sourceData as? MutableAudioEntitySourceData, let selectedIndicies = tableView.indexPathsForSelectedRows else {
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
		
		let kmvc = KyoozMenuViewController()
		kmvc.menuTitle = "Delete \(tableView.indexPathsForSelectedRows?.count ?? 0) Selected Items?"
		kmvc.addActions([KyoozMenuAction(title:"YES", image: nil) {
			deleteInternal()
			}])
		KyoozUtils.showMenuViewController(kmvc)
		
	}
	
}

