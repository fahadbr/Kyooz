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
private let identityTransform:CATransform3D = {
    var identity = CATransform3DIdentity
    identity.m34 = -1.0/1000
    return identity
}()

class ParentMediaEntityHeaderViewController : ParentMediaEntityViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    private enum HeaderState : Int {
        case Collapsed, Expanded, Transitioning
    }
    
//    static let queueButton:UIBarButtonItem = {
//        let view = ListButtonView()
//        view.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 40, height: 40))
//        view.addTarget(ContainerViewController.instance, action: "toggleSidePanel", forControlEvents: .TouchUpInside)
//        return UIBarButtonItem(customView: view)
//    }()
    
    static let searchButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: RootViewController.instance, action: "activateSearch")
	
	var sourceData:AudioEntitySourceData = MediaQuerySourceData(filterQuery: LibraryGrouping.Artists.baseQuery, libraryGrouping: LibraryGrouping.Artists)
    
    var datasourceDelegate:AudioEntityDSDProtocol! {
        didSet {
            tableView.dataSource = datasourceDelegate
            delegate = datasourceDelegate
        }
    }
    
    var delegate:UITableViewDelegate! {
        didSet {
            tableView.delegate = delegate
            toolbarItems = (delegate as? AudioEntitySelectorDSD)?.toolbarItems
        }
    }
	
    @IBOutlet var headerView:UIView!
    @IBOutlet var scrollView:UIScrollView!
    
    @IBOutlet var headerTopAnchorConstraint:NSLayoutConstraint!
    @IBOutlet var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var subHeaderHeightConstraint: NSLayoutConstraint!
    
    var headerHeight:CGFloat {
        return headerHeightConstraint.constant
    }
    
    var reuseIdentifier:String {
        if self is AlbumTrackTableViewController {
            return AlbumTrackTableViewCell.reuseIdentifier
        }
        
        if sourceData.libraryGrouping == LibraryGrouping.Albums {
            return ImageTableViewCell.reuseIdentifier
        }
        return MediaCollectionTableViewCell.reuseIdentifier
    }
    
    private var headerState:HeaderState = .Expanded
    
    private var headerTranslationTransform:CATransform3D!
    
    var testDelegate:TestTableViewDataSourceDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyDataSourceAndDelegate()
        navigationItem.rightBarButtonItem = ParentMediaEntityHeaderViewController.searchButton
        
        headerView.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        headerTranslationTransform = CATransform3DMakeTranslation(0, headerHeightConstraint.constant/2, 0)
        headerView.layer.transform = headerTranslationTransform
        headerView.layer.rasterizationScale = UIScreen.mainScreen().scale
        
//        configureTestDelegates()
        if scrollView != nil {
            configureOverlayScrollView()
        }
        
        popGestureRecognizer.delegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadAllData",
            name: KyoozPlaylistManager.PlaylistSetUpdate, object: KyoozPlaylistManager.instance)
    }
    
    private func configureTestDelegates() {
        testDelegate = TestTableViewDataSourceDelegate()
        testDelegate.mediaEntityTVC = self
        tableView.dataSource = testDelegate
        tableView.delegate = testDelegate
        tableView.sectionHeaderHeight = 40
        tableView.rowHeight = 60
    }
    
    private func configureOverlayScrollView() {
        view.addGestureRecognizer(scrollView.panGestureRecognizer)
        calculateContentSize()
    }
    
    private func calculateContentSize() {
        if scrollView == nil { return }
        let heightForSections = tableView.sectionHeaderHeight * CGFloat(tableView.numberOfSections > 1 ? tableView.numberOfSections : 0)
        var heightForCells:CGFloat = 0
        for i in 0..<tableView.numberOfSections {
            heightForCells += (tableView.rowHeight * CGFloat(tableView.numberOfRowsInSection(i)))
        }
        let estimatedHeight = heightForSections + heightForCells
        let totalHeight = estimatedHeight + headerHeightConstraint.constant + (subHeaderHeightConstraint?.constant ?? 0)!
        
        scrollView.contentSize = CGSize(width: view.frame.width, height: totalHeight)
        
        let shouldUseOverlay = totalHeight >= view.frame.height
        scrollView.userInteractionEnabled = shouldUseOverlay
        scrollView.scrollsToTop = shouldUseOverlay
        tableView.scrollEnabled = !shouldUseOverlay
        tableView.scrollsToTop = !shouldUseOverlay
    }
    
    
    
    
    //MARK: - Class functions
    override func reloadAllData() {
        super.reloadAllData()
        calculateContentSize()
    }
    
    
    override func reloadSourceData() {
        sourceData.reloadSourceData()
    }
    
    
    @IBAction func toggleSelectMode(sender:UIButton?) {
        let willEdit = !tableView.editing
        
        tableView.setEditing(willEdit, animated: true)
        RootViewController.instance.setToolbarHidden(!willEdit)
        
        if willEdit {
            sender?.setTitle("CANCEL", forState: .Normal)
            self.delegate = AudioEntitySelectorDSD(sourceData: sourceData, tableView: tableView)
        } else {
            sender?.setTitle("SELECT", forState: .Normal)
            applyDataSourceAndDelegate()
        }
        dispatch_after(KyoozUtils.getDispatchTimeForSeconds(0.5), dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
    
    
    @IBAction final func shuffleAllItems(sender:UIButton?) {
        playAllItems(sender, shouldShuffle: true)
    }
    
    @IBAction final func playAllItems(sender:UIButton?) {
        playAllItems(sender, shouldShuffle: false)
    }
    
    func applyDataSourceAndDelegate() {
        fatalError(fatalErrorMessage)
    }
    
    private func playAllItems(sender:UIButton?, shouldShuffle:Bool) {
        KyoozUtils.doInMainQueueAsync() { [audioQueuePlayer = self.audioQueuePlayer, sourceData = self.sourceData] in
            if let items = (sourceData as? MediaQuerySourceData)?.filterQuery.items where !items.isEmpty {
                audioQueuePlayer.playNow(withTracks: items, startingAtIndex: shouldShuffle ? KyoozUtils.randomNumber(belowValue: items.count):0, shouldShuffleIfOff: shouldShuffle)
            }
        }
    }
    
    //MARK: - Scroll View Delegate
    final func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView === tableView { return }
        let currentOffset = scrollView.contentOffset.y
        
        
        if currentOffset > 0 && currentOffset < headerHeight {
            headerView.layer.shouldRasterize = true
            applyTransformToHeaderUsingOffset(currentOffset)
        } else if currentOffset <= 0 {
            if headerState != .Expanded {
                headerView.layer.shouldRasterize = false
                applyTransformToHeaderUsingOffset(0)
            }
            tableView.contentOffset.y = currentOffset
        } else {
            if headerState != .Collapsed {
                headerView.layer.shouldRasterize = false
                applyTransformToHeaderUsingOffset(headerHeight)
            }
            tableView.contentOffset.y = currentOffset - headerHeight
        }
        
    }
    
    final func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        return !ContainerViewController.instance.sidePanelExpanded
    }
    
    
    private func applyTransformToHeaderUsingOffset(offset:CGFloat) {
        headerTopAnchorConstraint.constant = -offset
        let fraction = offset/headerHeight
        
        let angle = fraction * CGFloat(M_PI_2)
        
        let rotateTransform = CATransform3DRotate(identityTransform, angle, 1.0, 0.0, 0.0)
        headerView.layer.transform = CATransform3DConcat(rotateTransform, headerTranslationTransform)
        headerView.alpha = 1 - fraction
        
        if fraction == 1 {
            headerState = .Collapsed
        } else if fraction == 0 {
            headerState = .Expanded
        } else {
            headerState = .Transitioning
        }
    }
    
    func synchronizeOffsetWithScrollview(scrollView:UIScrollView) {
        if self.scrollView == nil { return }
        let currentOffset = scrollView.contentOffset.y
        if scrollView === tableView && currentOffset >= 0 {
            var expectedOffset = currentOffset
            if currentOffset > 0 {
                expectedOffset += headerHeight
            } else {
                expectedOffset += -headerTopAnchorConstraint.constant
            }
            let diff = fabs(expectedOffset - self.scrollView.contentOffset.y)
            if diff > 0 {
                self.scrollView.setContentOffset(CGPoint(x: 0, y: expectedOffset), animated: false)
            }
            return
        }
    }
    

    
    //MARK: - GESTURE RECOGNIZER DELEGATE
    final func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer === popGestureRecognizer {
            return gestureRecognizer === scrollView.panGestureRecognizer || gestureRecognizer === tableView.panGestureRecognizer
        }
        return false
    }
    final func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    final func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === popGestureRecognizer {
            return otherGestureRecognizer === scrollView.panGestureRecognizer || otherGestureRecognizer === tableView.panGestureRecognizer
        }
        return false
    }
    
    
}
