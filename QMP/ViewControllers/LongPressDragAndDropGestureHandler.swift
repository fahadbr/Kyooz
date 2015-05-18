//
//  LongPressDragAndDropGestureHandler.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer


class LongPressDragAndDropGestureHandler : LongPressToDragGestureHandler{
    
    let dragSource:DragSource
    let dropDestination:DropDestination
    
    var itemsToDrag:[MPMediaItem]!

    
    init(dragSource:DragSource, dropDestination:DropDestination) {
        self.dragSource = dragSource
        self.dropDestination = dropDestination
        super.init(tableView: dropDestination.destinationTableView)
        self.positionChangeUpdatesDataSource = false
        self.shouldHideSourceView = false
    }
    

    
    override func getCellForSnapshot(sender: UIGestureRecognizer, tableView: UITableView) -> (cell: UITableViewCell, indexPath: NSIndexPath)? {
        if let tableView = dragSource.sourceTableView, let result = super.getCellForSnapshot(sender, tableView: tableView) {
            if let items = dragSource.getItemsToDrag(result.indexPath) {
                itemsToDrag = items
            }
            return result
        }
        return nil
    }
    
    override func getTableViewScrollController() -> TableViewScrollPositionController {
        return TableViewScrollPositionController(tableView: dropDestination.destinationTableView, delegate: self)
    }
    
    override func updateSnapshotPosition(snapshot: UIView, sender: UIGestureRecognizer, locationInDestinationTableView: CGPoint) {
        let location = sender.locationInView(sender.view)
        snapshot.center = location
    }
    
    override func removeSnapshotFromView(viewToFadeIn: UIView?, viewToFadeOut: UIView, completionHandler: (Bool) -> ()) {
        super.removeSnapshotFromView(nil, viewToFadeOut: viewToFadeOut, completionHandler: completionHandler)
    }
    
    override func gestureDidBegin(sender: UIGestureRecognizer) {
        super.gestureDidBegin(sender)
        let tableView = dropDestination.destinationTableView
        let location = sender.locationInView(tableView)
        var destinationIndexPath = tableView.indexPathForRowAtPoint(CGPoint(x: 0, y: location.y))
        if(destinationIndexPath == nil) {
            destinationIndexPath = NSIndexPath(forRow: tableView.dataSource!.tableView(tableView, numberOfRowsInSection: 0) - 1, inSection: 0)
        }
        indexPathOfMovingItem = destinationIndexPath
        tableView.insertRowsAtIndexPaths([destinationIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
        

    }
    
    override func gestureDidEnd(sender: UIGestureRecognizer) {
        super.gestureDidEnd(sender)
        
        let tableView = dropDestination.destinationTableView
        let location = sender.locationInView(tableView)
        let insideTableView = tableView.pointInside(location, withEvent: nil)
        let localItemsToInsert = itemsToDrag
        let localIndexPathForInserting = indexPathOfMovingItem
        
        tableView.deleteRowsAtIndexPaths([localIndexPathForInserting], withRowAnimation: UITableViewRowAnimation.Fade)
        
        if(insideTableView) {
            if(localItemsToInsert != nil) {
                var indexPaths = [NSIndexPath]()
                let startingIndex = localIndexPathForInserting.row
                for index in (startingIndex)..<(startingIndex+localItemsToInsert.count)  {
                    indexPaths.append(NSIndexPath(forRow: index, inSection: 0))
                }
                
                dropDestination.setDropItems(localItemsToInsert!, atIndex:localIndexPathForInserting)
                tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Fade)
            }
        }
    }
}

protocol DragSource {

    var sourceTableView:UITableView? { get }
    
    func getItemsToDrag(indexPath:NSIndexPath) -> [MPMediaItem]?
    
}

protocol DropDestination {
    
    var destinationTableView:UITableView { get }
    
    func setDropItems(dropItems:[MPMediaItem], atIndex:NSIndexPath)
    
}