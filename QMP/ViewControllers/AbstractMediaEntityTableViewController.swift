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

class AbstractMediaEntityTableViewController : AbstractViewController, MediaItemTableViewControllerProtocol, UIScrollViewDelegate {
    
    private static let greenColor = UIColor(red: 0.0/225.0, green: 184.0/225.0, blue: 24.0/225.0, alpha: 1)
    private static let blueColor = UIColor(red: 51.0/225.0, green: 62.0/225.0, blue: 222.0/225.0, alpha: 1)
    
    let fatalErrorMessage = "Unsupported operation. this is an abstract class"
    let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    var libraryGroupingType:LibraryGrouping! = LibraryGrouping.Artists
    var filterQuery:MPMediaQuery! = LibraryGrouping.Artists.baseQuery
    weak var parentMediaEntityController:MediaEntityViewController?
    
    @IBOutlet var tableView:UITableView!
    @IBOutlet var headerView: UIView!
    @IBOutlet var scrollView:UIScrollView!
    
    @IBOutlet var headerTopAnchorConstraint:NSLayoutConstraint!
    @IBOutlet var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var subHeaderHeightConstraint: NSLayoutConstraint!
    
    var headerHeight:CGFloat {
        return headerHeightConstraint.constant
    }
    
    private var headerCollapsed:Bool = false
    private var headerTranslationTransform:CATransform3D!
    
    private var playNextButton:UIBarButtonItem!
    private var playLastButton:UIBarButtonItem!
    private var playRandomlyButton:UIBarButtonItem!
    private var selectAllButton:UIBarButtonItem!
    private var selectedIndicies:[NSIndexPath]!
    
    var testDelegate:TestTableViewDataSourceDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 60
        tableView.estimatedSectionHeaderHeight = 40
        tableView.allowsMultipleSelectionDuringEditing = true
        reloadSourceData()
        registerForNotifications()
        
        headerView.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        headerTranslationTransform = CATransform3DMakeTranslation(0, headerHeight/2, 0)
        headerView.layer.transform = headerTranslationTransform
        
        configureTestDelegates()
        configureOverlayScrollView()
    }
    
    deinit {
        unregisterForNotifications()
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
        let totalHeight = estimatedHeight + headerHeightConstraint.constant + subHeaderHeightConstraint.constant
        
        scrollView.contentSize = CGSize(width: view.frame.width, height: totalHeight)
        
        let shouldUseOverlay = totalHeight >= view.frame.height
        scrollView.userInteractionEnabled = shouldUseOverlay
        scrollView.scrollsToTop = shouldUseOverlay
        tableView.scrollEnabled = !shouldUseOverlay
        tableView.scrollsToTop = !shouldUseOverlay
        
        Logger.debug("calculated content size: \(scrollView.contentSize)")
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let mediaItems = getMediaItemsForIndexPath(indexPath)
        var actions = [UITableViewRowAction]()
        
        
        let playLastAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Play\nLast",
                handler: {action, index in
                    self.audioQueuePlayer.enqueue(items: mediaItems, atPosition: .Last)
                    self.tableView.delegate?.tableView?(tableView, didEndEditingRowAtIndexPath: indexPath)
            })
        actions.append(playLastAction)
        let playNextAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Play\nNext",
            handler: {action, index in
                self.audioQueuePlayer.enqueue(items: mediaItems, atPosition: .Next)
                self.tableView.delegate?.tableView?(tableView, didEndEditingRowAtIndexPath: indexPath)
        })
        actions.append(playNextAction)
        
        if audioQueuePlayer.shuffleActive {
            let playRandomlyAction = UITableViewRowAction(style: .Normal, title: "Play\nRandomly", handler: { (action, index) -> Void in
                self.audioQueuePlayer.enqueue(items: mediaItems, atPosition: .Random)
                self.tableView.delegate?.tableView?(tableView, didEndEditingRowAtIndexPath: indexPath)
            })
            actions.append(playRandomlyAction)
        }
        
        
        playLastAction.backgroundColor = AbstractMediaEntityTableViewController.blueColor
        playNextAction.backgroundColor = AbstractMediaEntityTableViewController.greenColor

        
        return actions
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

    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    //MARK: - Class functions
    func reloadAllData() {
        Logger.debug("Reloading all media entity data")
        if tableView.editing {
            selectedIndicies.removeAll()
        }
        reloadSourceData()
        reloadTableViewData()
        parentMediaEntityController?.calculateContentSize()
    }
    
    func reloadTableViewData() {
        refreshButtonStates()
        tableView.reloadData()
    }
    
    func reloadSourceData() {
        fatalError(fatalErrorMessage)
    }
    
    @IBAction final func toggleSelectMode(sender:UIButton?) {
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
        if parentViewController != nil && !parentViewController!.automaticallyAdjustsScrollViewInsets {
            UIView.animateWithDuration(0.25) {
                let newInset:CGFloat = willEdit ? 44 : 0
                self.tableView.contentInset.bottom = newInset
            }
        }
        
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
        KyoozUtils.doInMainQueueAsync() {
            if let items = self.filterQuery.items where !items.isEmpty {
                self.audioQueuePlayer.playNow(withTracks: items, startingAtIndex: KyoozUtils.randomNumber(belowValue: items.count)) {
                    if !self.audioQueuePlayer.shuffleActive {
                        self.audioQueuePlayer.shuffleActive = true
                    }
                }
            }
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView === tableView { return }
        let currentOffset = scrollView.contentOffset.y
        
        
        if currentOffset > 0 && currentOffset < headerHeight {
            applyTransformToHeaderUsingOffset(currentOffset)
        } else if currentOffset <= 0 {
            if headerCollapsed {
                applyTransformToHeaderUsingOffset(0)
            }
            tableView.contentOffset.y = currentOffset
        } else {
            if !headerCollapsed {
                applyTransformToHeaderUsingOffset(headerHeight)
            }
            tableView.contentOffset.y = currentOffset - headerHeight
        }
        
    }
    
    
    private func applyTransformToHeaderUsingOffset(offset:CGFloat) {
        headerTopAnchorConstraint.constant = -offset
        let fraction = offset/headerHeight
        
        let angle = fraction * CGFloat(M_PI_2)
        
        let rotateTransform = CATransform3DRotate(identityTransform, angle, 1.0, 0.0, 0.0)
        headerView.layer.transform = CATransform3DConcat(rotateTransform, headerTranslationTransform)
        headerView.alpha = 1 - fraction
        
        if fraction == 1 {
            headerCollapsed = true
        } else if fraction == 0{
            headerCollapsed = false
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
    
    func configureBackgroundImage(view:UIView) {
        
    }
    
    //MARK: - Overriding MediaItemTableViewController methods
    func getMediaItemsForIndexPath(indexPath: NSIndexPath) -> [AudioTrack] {
        fatalError(fatalErrorMessage)
    }
    
    func getViewForHeader() -> UIView? {
        return nil
    }
    
    //MARK: - Private functions
    
    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "reloadTableViewData",
            name: AudioQueuePlayerUpdate.NowPlayingItemChanged.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadTableViewData",
            name: AudioQueuePlayerUpdate.PlaybackStateUpdate.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadAllData",
            name: MPMediaLibraryDidChangeNotification, object: MPMediaLibrary.defaultMediaLibrary())
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}
