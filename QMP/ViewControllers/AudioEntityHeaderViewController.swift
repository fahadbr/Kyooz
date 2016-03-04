//
//  AudioEntityViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/3/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

private enum HeaderState : Int {
	case Collapsed, Expanded, Transitioning
}
private let searchButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: RootViewController.instance, action: "activateSearch")

final class AudioEntityHeaderViewController<T:AudioEntityDSDProtocol> : AudioEntityViewController<T>, UIScrollViewDelegate, UIGestureRecognizerDelegate {
	
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
	
	
	func applyDataSourceAndDelegate() {
		fatalError(fatalErrorMessage)
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
