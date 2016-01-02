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

class AbstractMediaEntityTableViewController : AbstractTableViewController, MediaItemTableViewControllerProtocol {
    
    private static let greenColor = UIColor(red: 0.0/225.0, green: 184.0/225.0, blue: 24.0/225.0, alpha: 1)
    private static let blueColor = UIColor(red: 51.0/225.0, green: 62.0/225.0, blue: 222.0/225.0, alpha: 1)
    
    let fatalErrorMessage = "Unsupported operation. this is an abstract class"
    let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    var libraryGroupingType:LibraryGrouping! = LibraryGrouping.Artists
    var filterQuery:MPMediaQuery! = LibraryGrouping.Artists.baseQuery
    weak var parentMediaEntityController:MediaEntityViewController?
    
    var headerHeight:CGFloat {
        return 40
    }
    
    private var playNextButton:UIBarButtonItem!
    private var playLastButton:UIBarButtonItem!
    private var playRandomlyButton:UIBarButtonItem!
    private var selectAllButton:UIBarButtonItem!
    private var selectedIndicies:[NSIndexPath]!
    
    var testDelegate:TestTableViewDataSourceDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 60
        tableView.allowsMultipleSelectionDuringEditing = true
        reloadSourceData()
        registerForNotifications()
        
//        testDelegate = TestTableViewDataSourceDelegate()
//        tableView.dataSource = testDelegate
//        tableView.delegate = testDelegate
    }
    
    deinit {
        unregisterForNotifications()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let mediaItems = getMediaItemsForIndexPath(indexPath)
        var actions = [UITableViewRowAction]()
        
        
        let playLastAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Play\nLast",
                handler: {action, index in
                    self.audioQueuePlayer.enqueue(items: mediaItems, atPosition: .Last)
                    self.tableView(tableView, didEndEditingRowAtIndexPath: indexPath)
            })
        actions.append(playLastAction)
        let playNextAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Play\nNext",
            handler: {action, index in
                self.audioQueuePlayer.enqueue(items: mediaItems, atPosition: .Next)
                self.tableView(tableView, didEndEditingRowAtIndexPath: indexPath)
        })
        actions.append(playNextAction)
        
        if audioQueuePlayer.shuffleActive {
            let playRandomlyAction = UITableViewRowAction(style: .Normal, title: "Play\nRandomly", handler: { (action, index) -> Void in
                self.audioQueuePlayer.enqueue(items: mediaItems, atPosition: .Random)
                self.tableView(tableView, didEndEditingRowAtIndexPath: indexPath)
            })
            actions.append(playRandomlyAction)
        }
        
        
        playLastAction.backgroundColor = AbstractMediaEntityTableViewController.blueColor
        playNextAction.backgroundColor = AbstractMediaEntityTableViewController.greenColor

        
        return actions
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(tableView.editing) {
            selectedIndicies?.append(indexPath)
            refreshButtonStates()
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
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
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
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
    
    final func toggleSelectMode(sender:UIButton?) -> Bool {
        if parentViewController?.toolbarItems == nil {
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
            
            parentViewController?.toolbarItems = [playNextButton, createFlexibleSpace(), playLastButton,
                createFlexibleSpace(), playRandomlyButton, createFlexibleSpace(), selectAllButton]
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
        if parentViewController != nil && !parentViewController!.automaticallyAdjustsScrollViewInsets {
            UIView.animateWithDuration(0.25) {
                self.tableView.contentInset.bottom = willEdit ? 44 : 0
            }
        }
        
        refreshButtonStates()
        return willEdit
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
    
    final func shuffleAllItems(sender:UIButton?) {
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
