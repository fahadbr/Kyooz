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

final class AudioEntitySelectorDSD : AudioEntityDSD  {
    
    private let playNextButton:UIBarButtonItem = UIBarButtonItem(title: "Play Next", style: .Plain, target: nil, action: "insertSelectedItemsIntoQueue:")
    private let playLastButton:UIBarButtonItem = UIBarButtonItem(title: "Play Last", style: .Plain, target: nil, action: "insertSelectedItemsIntoQueue:")
    private let playRandomlyButton:UIBarButtonItem = UIBarButtonItem(title: "Play Randomly", style: .Plain, target: nil, action: "insertSelectedItemsIntoQueue:")
    private let selectAllButton:UIBarButtonItem = UIBarButtonItem(title: selectAllString, style: UIBarButtonItemStyle.Done, target: nil, action: "selectOrDeselectAll")
    let toolbarItems:[UIBarButtonItem]
    
    private var selectedIndicies:[NSIndexPath]
    
    private let tableView:UITableView

    
    init(sourceData:AudioEntitySourceData, tableView:UITableView, reuseIdentifier:String, audioCellDelegate:ParentMediaEntityHeaderViewController) {
        self.tableView = tableView
        selectedIndicies = [NSIndexPath]()
        
        func createFlexibleSpace() -> UIBarButtonItem {
            return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        }
        
        toolbarItems = [playNextButton, createFlexibleSpace(), playLastButton, createFlexibleSpace(), playRandomlyButton, createFlexibleSpace(), selectAllButton]
        super.init(sourceData: sourceData, reuseIdentifier:reuseIdentifier, audioCellDelegate:audioCellDelegate)
        let tintColor = ThemeHelper.defaultTintColor
        toolbarItems.forEach() {
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
        
        playNextButton.enabled = isNotEmpty
        playLastButton.enabled = isNotEmpty
        playRandomlyButton.enabled = isNotEmpty
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
    
    func insertSelectedItemsIntoQueue(sender:UIBarButtonItem!) {
        if selectedIndicies.isEmpty {
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
            
            items.appendContentsOf(sourceData.getTracksAtIndex(indexPath))
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
    
    
}
