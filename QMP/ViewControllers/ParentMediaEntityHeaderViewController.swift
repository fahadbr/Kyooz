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
    
    static let queueButton:UIBarButtonItem = {
        let view = ListButtonView()
        view.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 40, height: 40))
        view.addTarget(ContainerViewController.instance, action: "toggleSidePanel", forControlEvents: .TouchUpInside)
        return UIBarButtonItem(customView: view)
    }()
    
    static let searchButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: RootViewController.instance, action: "activateSearch")
    
    var libraryGroupingType:LibraryGrouping! = LibraryGrouping.Artists
    var filterQuery:MPMediaQuery! = LibraryGrouping.Artists.baseQuery
    
    @IBOutlet var headerView:UIView!
    @IBOutlet var scrollView:UIScrollView!
    
    @IBOutlet var headerTopAnchorConstraint:NSLayoutConstraint!
    @IBOutlet var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var subHeaderHeightConstraint: NSLayoutConstraint!
    
    var headerHeight:CGFloat {
        return headerHeightConstraint.constant
    }
    
    private var headerState:HeaderState = .Expanded
    
    private var headerTranslationTransform:CATransform3D!
    
    private var playNextButton:UIBarButtonItem!
    private var playLastButton:UIBarButtonItem!
    private var playRandomlyButton:UIBarButtonItem!
    private var selectAllButton:UIBarButtonItem!
    private var selectedIndicies:[NSIndexPath]!
    
    var testDelegate:TestTableViewDataSourceDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItems = [ParentMediaEntityHeaderViewController.queueButton, ParentMediaEntityHeaderViewController.searchButton]
        
        headerView.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        headerTranslationTransform = CATransform3DMakeTranslation(0, headerHeightConstraint.constant/2, 0)
        headerView.layer.transform = headerTranslationTransform
        headerView.layer.rasterizationScale = UIScreen.mainScreen().scale
        
//        configureTestDelegates()
        if scrollView != nil {
            configureOverlayScrollView()
        }
        
        popGestureRecognizer.delegate = self
    }
    
    private func configureTestDelegates() {
        testDelegate = TestTableViewDataSourceDelegate()
        testDelegate.mediaEntityTVC = self
        tableView.dataSource = testDelegate
        tableView.delegate = testDelegate
        tableView.estimatedSectionHeaderHeight = 40
        tableView.estimatedRowHeight = 60
    }
    
    private func configureOverlayScrollView() {
        view.addGestureRecognizer(scrollView.panGestureRecognizer)
        calculateContentSize()
    }
    
    private func calculateContentSize() {
        if scrollView == nil { return }
        let heightForSections = tableView.estimatedSectionHeaderHeight * CGFloat(tableView.numberOfSections > 1 ? tableView.numberOfSections : 0)
        var heightForCells:CGFloat = 0
        for i in 0..<tableView.numberOfSections {
            heightForCells += (tableView.estimatedRowHeight * CGFloat(tableView.numberOfRowsInSection(i)))
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
    
    
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(tableView.editing) {
            selectedIndicies?.append(indexPath)
            refreshButtonStates()
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if(tableView.editing) {
            var indexToRemove:Int?
            for (index, indexPathToDelete) in selectedIndicies.enumerate() {
                if(indexPathToDelete == indexPath) {
                    indexToRemove = index
                    break;
                }
            }
            if(indexToRemove != nil) {
                selectedIndicies?.removeAtIndex(indexToRemove!)
            }
            refreshButtonStates()
        }
    }

    
    //MARK: - Class functions
    override func reloadAllData() {
        super.reloadAllData()
        if tableView.editing {
            selectedIndicies.removeAll()
        }
        calculateContentSize()
    }
    
    override func reloadTableViewData() {
        super.reloadTableViewData()
        refreshButtonStates()
    }
    
    
    @IBAction final func toggleSelectMode(sender:UIButton?) {
        if toolbarItems == nil || toolbarItems!.isEmpty {
            selectAllButton = UIBarButtonItem(title: selectAllString, style: UIBarButtonItemStyle.Done, target: self, action: "selectOrDeselectAll")
            playNextButton = UIBarButtonItem(title: "Play Next", style: .Plain, target: self, action: "insertSelectedItemsIntoQueue:")
            playLastButton = UIBarButtonItem(title: "Play Last", style: .Plain, target: self, action: "insertSelectedItemsIntoQueue:")
            playRandomlyButton = UIBarButtonItem(title: "Play Randomly", style: .Plain, target: self, action: "insertSelectedItemsIntoQueue:")
            selectAllButton.tintColor = ThemeHelper.defaultTintColor
            playNextButton.tintColor = ThemeHelper.defaultTintColor
            playLastButton.tintColor = ThemeHelper.defaultTintColor
            playRandomlyButton.tintColor = ThemeHelper.defaultTintColor
            
            func createFlexibleSpace() -> UIBarButtonItem {
                return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            }
            
            toolbarItems = [playNextButton, createFlexibleSpace(), playLastButton, createFlexibleSpace(), playRandomlyButton, createFlexibleSpace(), selectAllButton]
        }
        
        let willEdit = !tableView.editing
        if willEdit {
            selectedIndicies = [NSIndexPath]()
            sender?.setTitle("CANCEL", forState: .Normal)
        } else {
            selectedIndicies = nil
            sender?.setTitle("SELECT", forState: .Normal)
        }
        
        tableView.setEditing(willEdit, animated: true)
        RootViewController.instance.setToolbarHidden(!willEdit)
        
        refreshButtonStates()
    }
    
    private func refreshButtonStates() {
        if selectedIndicies == nil { return }
        
        let isNotEmpty = !selectedIndicies.isEmpty

        playNextButton.enabled = isNotEmpty
        playLastButton.enabled = isNotEmpty
        playRandomlyButton.enabled = isNotEmpty && audioQueuePlayer.shuffleActive
        selectAllButton.title = isNotEmpty ? deselectAllString : selectAllString
    }
    
    final func selectOrDeselectAll() {
        if selectedIndicies == nil {
            return
        }
        
        if selectedIndicies.isEmpty {
            for section in 0 ..< tableView.numberOfSections {
                for row in 0 ..< tableView.numberOfRowsInSection(section) {
                    let indexPath = NSIndexPath(forRow: row, inSection: section)
                    tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
                    selectedIndicies.append(indexPath)
                }
            }
        } else {
            for indexPath in selectedIndicies {
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
            }
            selectedIndicies.removeAll()
        }
        
        refreshButtonStates()
    }
    
    final func insertSelectedItemsIntoQueue(sender:UIBarButtonItem!) {
        if selectedIndicies == nil || selectedIndicies.isEmpty {
            return
        }
        
        selectedIndicies.sortInPlace { (first, second) -> Bool in
            if first.section < second.section {
                return true
            }
            if first.row < second.row {
                return true
            }
            return false
        }
        
        var items = [AudioTrack]()
        for indexPath in selectedIndicies {
            items.appendContentsOf(getMediaItemsForIndexPath(indexPath))
        }
        
        if sender === playNextButton {
            audioQueuePlayer.enqueue(items: items, atPosition: .Next)
        } else if sender === playLastButton {
            audioQueuePlayer.enqueue(items: items, atPosition: .Last)
        } else if sender === playRandomlyButton {
            audioQueuePlayer.enqueue(items: items, atPosition: .Random)
        }
        selectOrDeselectAll()
    }
    
    @IBAction final func shuffleAllItems(sender:UIButton?) {
        playAllItems(sender, shouldShuffle: true)
    }
    
    @IBAction final func playAllItems(sender:UIButton?) {
        playAllItems(sender, shouldShuffle: false)
    }
    
    private func playAllItems(sender:UIButton?, shouldShuffle:Bool) {
        KyoozUtils.doInMainQueueAsync() { [audioQueuePlayer = self.audioQueuePlayer, filterQuery = self.filterQuery] in
            if let items = filterQuery.items where !items.isEmpty {
                audioQueuePlayer.playNow(withTracks: items, startingAtIndex: shouldShuffle ? KyoozUtils.randomNumber(belowValue: items.count):0) {
                    if shouldShuffle && !audioQueuePlayer.shuffleActive {
                        audioQueuePlayer.shuffleActive = true
                    } else if !shouldShuffle && audioQueuePlayer.shuffleActive {
                        audioQueuePlayer.shuffleActive = false
                    }
                }
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
