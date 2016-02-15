//
//  AudioEntitySelectorTVDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

private let selectAllString = "Select All"
private let deselectAllString = "Deselect All"

final class AudioEntitySelectorDSD : AudioEntityTableViewDelegate  {
    
    private let playButton:UIBarButtonItem = UIBarButtonItem(title: "Play", style: .Plain, target: nil, action: "playSelectedTracks:")
    private let queueButton:UIBarButtonItem = UIBarButtonItem(title: "Queue..", style: .Plain, target: nil, action: "showQueueOptions:")
    private let addToButton:UIBarButtonItem = UIBarButtonItem(title: "Add To..", style: .Plain, target: nil, action: "addToPlaylist")
    private let selectAllButton:UIBarButtonItem = UIBarButtonItem(title: selectAllString, style: UIBarButtonItemStyle.Done, target: nil, action: "selectOrDeselectAll")
    private let deleteButton:UIBarButtonItem = UIBarButtonItem(title: "Delete", style: .Plain, target: nil, action: "deleteSelectedItems")
    
    let toolbarItems:[UIBarButtonItem]
    
    
    
    private var selectedIndicies:[NSIndexPath]
    private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    private let tableView:UITableView

    
    init(sourceData:AudioEntitySourceData, tableView:UITableView) {
        self.tableView = tableView
        selectedIndicies = [NSIndexPath]()
        
        func createFlexibleSpace() -> UIBarButtonItem {
            return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        }
        
        var toolbarItems = [playButton, createFlexibleSpace(), queueButton, createFlexibleSpace(), addToButton, createFlexibleSpace(), selectAllButton]
        
        if sourceData is MutableAudioEntitySourceData {
            toolbarItems.append(createFlexibleSpace())
            toolbarItems.append(deleteButton)
        }
        
        self.toolbarItems = toolbarItems
        
        super.init(sourceData: sourceData)
        let tintColor = ThemeHelper.defaultTintColor
        self.toolbarItems.forEach() {
            $0.target = self
            $0.tintColor = tintColor
        }
        refreshButtonStates()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(!tableView.editing) { return }
        
        selectedIndicies.append(indexPath)
        refreshButtonStates()
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if(!tableView.editing) { return }
        
        var indexToRemove:Int?
        for (index, indexPathToDelete) in selectedIndicies.enumerate() {
            if(indexPathToDelete == indexPath) {
                indexToRemove = index
                break;
            }
        }
        if(indexToRemove != nil) {
            selectedIndicies.removeAtIndex(indexToRemove!)
        }
        refreshButtonStates()
    }
    
    private func refreshButtonStates() {
        let isNotEmpty = !selectedIndicies.isEmpty
        
        playButton.enabled = isNotEmpty
        queueButton.enabled = isNotEmpty
        deleteButton.enabled = isNotEmpty
        addToButton.enabled = isNotEmpty
        selectAllButton.title = isNotEmpty ? deselectAllString : selectAllString
    }
    
    func selectOrDeselectAll() {
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
    
    private func getOrderedTracks() -> [AudioTrack]? {
        guard !selectedIndicies.isEmpty else { return nil }
        
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
    
    func playSelectedTracks(sender:UIBarButtonItem!) {
        guard let items = getOrderedTracks() else { return }
        
        audioQueuePlayer.playNow(withTracks: items, startingAtIndex: 0, shouldShuffleIfOff: false)

        selectOrDeselectAll()
    }
    
    func showQueueOptions(sender:UIBarButtonItem!) {
        guard let items = getOrderedTracks() else { return }
        
        let ac = UIAlertController(title: "\(selectedIndicies.count) Selected Items", message: nil, preferredStyle: .Alert)
        KyoozUtils.addDefaultQueueingActions(items, alertController: ac) {
            self.selectOrDeselectAll()
        }
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        ContainerViewController.instance.presentViewController(ac, animated: true, completion:  nil)
    }
    
    func addToPlaylist() {
        guard let items = getOrderedTracks() else { return }
        KyoozUtils.showAvailablePlaylistsForAddingTracks(items) {
            self.selectOrDeselectAll()
        }
    }
    
    func deleteSelectedItems() {

        let ac = UIAlertController(title: "Delete \(selectedIndicies.count) Selected Items?", message: nil, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "Yes", style: .Destructive, handler: { _ -> Void in
            self.deleteInternal()
        }))
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        ContainerViewController.instance.presentViewController(ac, animated: true, completion:  nil)
                
    }
    
    private func deleteInternal() {
        guard let mutableSourceData = self.sourceData as? MutableAudioEntitySourceData else {
            return
        }
        do {
            try mutableSourceData.deleteEntitiesAtIndexPaths(selectedIndicies)
            tableView.deleteRowsAtIndexPaths(selectedIndicies, withRowAnimation: .Automatic)
            selectOrDeselectAll()
        } catch let error {
            KyoozUtils.showPopupError(withTitle: "Error occured while deleting items", withThrownError: error, presentationVC: nil)
        }

    }
    
    
}
