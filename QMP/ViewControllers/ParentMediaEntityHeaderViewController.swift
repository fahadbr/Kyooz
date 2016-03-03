//
//  AbstractMediaEntityTableViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 10/5/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

private let selectAllString = "Select All"
private let deselectAllString = "Deselect All"

class ParentMediaEntityHeaderViewController : ParentMediaEntityViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
	
	private enum HeaderState : Int {
		case Collapsed, Expanded, Transitioning
	}
	
	static let searchButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: RootViewController.instance, action: "activateSearch")
	
	var sourceData:AudioEntitySourceData = MediaQuerySourceData(filterQuery: LibraryGrouping.Artists.baseQuery, libraryGrouping: LibraryGrouping.Artists)
	
	var datasourceDelegate:AudioEntityDSDProtocol! {
		didSet {
			tableView.dataSource = datasourceDelegate
			tableView.delegate = datasourceDelegate
		}
	}
	
	
	@IBOutlet var headerView:UIView!
	
	@IBOutlet var headerTopAnchorConstraint:NSLayoutConstraint!
	@IBOutlet var headerHeightConstraint: NSLayoutConstraint!
	@IBOutlet var tableViewTopAnchorConstraint: NSLayoutConstraint!
	

	var maxHeight:CGFloat!
	var minHeight:CGFloat!
	var collapsedTargetOffset:CGFloat!
	
	var reuseIdentifier:String {
		if useCollectionDetailsHeader {
			return AlbumTrackTableViewCell.reuseIdentifier
		}
		
		if sourceData.libraryGrouping == LibraryGrouping.Albums {
			return ImageTableViewCell.reuseIdentifier
		}
		return MediaCollectionTableViewCell.reuseIdentifier
	}
	
	var shouldCollapseHeaderView = true
	var useCollectionDetailsHeader:Bool = false
	private var headerState:HeaderState = .Expanded
	
	var testMode = false
	var testDelegate:TestTableViewDataSourceDelegate!
	
	private lazy var addToButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "showAddToOptions:")
	private lazy var selectAllButton:UIBarButtonItem = UIBarButtonItem(title: selectAllString, style: .Plain, target: self, action: "selectOrDeselectAll")
	private lazy var deleteButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: "deleteSelectedItems")
	
	private lazy var playButton:UIBarButtonItem = {
		let playButtonView = PlayPauseButtonView()
		playButtonView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 40, height: 40))
		playButtonView.isPlayButton = true
		playButtonView.hasOuterFrame = false
		playButtonView.color = ThemeHelper.defaultTintColor
		playButtonView.addTarget(self, action: "playSelectedTracks:", forControlEvents: .TouchUpInside)
		return UIBarButtonItem(customView: playButtonView)
	}()
	
	private lazy var shuffleButton:UIBarButtonItem = {
		let shuffleButtonView = ShuffleButtonView()
		shuffleButtonView.color = ThemeHelper.defaultTintColor
		shuffleButtonView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 40, height: 40))
		shuffleButtonView.addTarget(self, action: "playSelectedTracks:", forControlEvents: .TouchUpInside)
		return UIBarButtonItem(customView: shuffleButtonView)
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if testMode {
			configureTestDelegates()
		} else {
			applyDataSourceAndDelegate()
		}
		
		navigationItem.rightBarButtonItem = ParentMediaEntityHeaderViewController.searchButton
		headerView.layer.rasterizationScale = UIScreen.mainScreen().scale
		if shouldCollapseHeaderView {
			KyoozUtils.doInMainQueueAsync() {
				self.tableViewTopAnchorConstraint.active = false
				self.tableViewTopAnchorConstraint = self.tableView.topAnchor.constraintEqualToAnchor(self.view.topAnchor, constant: self.minHeight)
				self.tableViewTopAnchorConstraint.active = true
				self.tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.collapsedTargetOffset))
				self.tableView.scrollIndicatorInsets.top = self.collapsedTargetOffset
				self.view.addGestureRecognizer(self.tableView.panGestureRecognizer)
			}
		}
		
		view.backgroundColor = ThemeHelper.darkAccentColor
		popGestureRecognizer.delegate = self
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadAllData",
			name: KyoozPlaylistManager.PlaylistSetUpdate, object: KyoozPlaylistManager.instance)
	}
	
	private func configureTestDelegates() {
		testDelegate = TestTableViewDataSourceDelegate()
		//        testDelegate.mediaEntityTVC = self
		tableView.dataSource = testDelegate
		tableView.delegate = testDelegate
		tableView.sectionHeaderHeight = 40
		tableView.rowHeight = 60
	}
	
	
	//MARK: - Class functions
	
	override func reloadSourceData() {
		sourceData.reloadSourceData()
	}
	
	
	@IBAction func toggleSelectMode(sender:UIButton?) {
		let willEdit = !tableView.editing
		
		tableView.setEditing(willEdit, animated: true)
		RootViewController.instance.setToolbarHidden(!willEdit)
		
		if willEdit && toolbarItems == nil {
			toolbarItems = createToolbarItems()
		}
		
		(sender as? ListButtonView)?.showBullets = !willEdit
		
		refreshButtonStates()
	}
	
	
	@IBAction final func shuffleAllItems(sender:UIButton?) {
		playAllItems(sender, shouldShuffle: true)
	}
	
	func applyDataSourceAndDelegate() {
		fatalError(fatalErrorMessage)
	}
	
	private func playAllItems(sender:UIButton?, shouldShuffle:Bool) {
		KyoozUtils.doInMainQueueAsync() { [sourceData = self.sourceData] in
			if let items = (sourceData as? MediaQuerySourceData)?.filterQuery.items where !items.isEmpty {
				self.playTracks(items, shouldShuffle: shouldShuffle)
			}
		}
	}
	
	private func playTracks(tracks:[AudioTrack], shouldShuffle:Bool) {
		audioQueuePlayer.playNow(withTracks: tracks, startingAtIndex: shouldShuffle ? KyoozUtils.randomNumber(belowValue: tracks.count):0, shouldShuffleIfOff: shouldShuffle)
	}
	
	//MARK: - Scroll View Delegate
	
	final func scrollViewDidScroll(scrollView: UIScrollView) {
		if !shouldCollapseHeaderView { return }
		let currentOffset = scrollView.contentOffset.y
		
		if  currentOffset < collapsedTargetOffset {
			applyTransformToHeaderUsingOffset(currentOffset)
			scrollView.scrollIndicatorInsets.top = collapsedTargetOffset - currentOffset
		} else if headerState != .Collapsed {
			applyTransformToHeaderUsingOffset(collapsedTargetOffset)
		}
	}
	
	
	final func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
		return !ContainerViewController.instance.sidePanelExpanded
	}
	
	
	private func applyTransformToHeaderUsingOffset(offset:CGFloat) {
		headerHeightConstraint.constant = (maxHeight - offset)
		let fraction = offset/collapsedTargetOffset
		
		if fraction == 1 {
			headerState = .Collapsed
		} else if fraction == 0 {
			headerState = .Expanded
		} else {
			headerState = .Transitioning
		}
	}
	
	//MARK: - Multi selection methods
	
	
	private func createToolbarItems() -> [UIBarButtonItem] {
		func createFlexibleSpace() -> UIBarButtonItem {
			return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
		}
		
		var toolbarItems = [playButton, createFlexibleSpace(), shuffleButton, createFlexibleSpace(), addToButton]
		
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
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshButtonStates", name: UITableViewSelectionDidChangeNotification, object: tableView)
		return toolbarItems
	}
	
	
	func refreshButtonStates() {
		let isNotEmpty = tableView.indexPathsForSelectedRows != nil
		
		playButton.enabled = isNotEmpty
		deleteButton.enabled = isNotEmpty
		addToButton.enabled = isNotEmpty
		shuffleButton.enabled = isNotEmpty
		selectAllButton.title = isNotEmpty ? deselectAllString : selectAllString
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
	}
	
	func showAddToOptions(sender:UIBarButtonItem!) {
		guard let items = getOrderedTracks() else { return }
		
		let ac = UIAlertController(title: "\(tableView.indexPathsForSelectedRows?.count ?? 0) Selected Items", message: nil, preferredStyle: .Alert)
		KyoozUtils.addDefaultQueueingActions(items, alertController: ac) {
			self.selectOrDeselectAll()
		}
		ac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
		
		ContainerViewController.instance.presentViewController(ac, animated: true, completion:  nil)
	}
	
	
	func deleteSelectedItems() {
		
		let ac = UIAlertController(title: "Delete \(tableView.indexPathsForSelectedRows?.count ?? 0) Selected Items?", message: nil, preferredStyle: .Alert)
		ac.addAction(UIAlertAction(title: "Yes", style: .Destructive, handler: { _ -> Void in
			self.deleteInternal()
		}))
		
		ac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
		
		ContainerViewController.instance.presentViewController(ac, animated: true, completion:  nil)
		
	}
	
	private func deleteInternal() {
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
	
	
	
	//MARK: - GESTURE RECOGNIZER DELEGATE
	final func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if otherGestureRecognizer === popGestureRecognizer {
			return gestureRecognizer === tableView.panGestureRecognizer
		}
		return false
	}
	final func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return false
	}
	
	final func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer === popGestureRecognizer {
			return otherGestureRecognizer === tableView.panGestureRecognizer
		}
		return false
	}
	
	
}
