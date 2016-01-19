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


final class LongPressDragAndDropGestureHandler : LongPressToDragGestureHandler{
    
    var dragSource:DragSource
    var dropDestination:DropDestination
    
    var itemsToDrag:[AudioTrack]!
    var cancelView:CancelView
    var cancelViewVisible:Bool = false

    override var indexPathOfMovingItem:NSIndexPath! {
        didSet {
            dropDestination.indexPathOfMovingItem = indexPathOfMovingItem
        }
    }
    
    init(dragSource:DragSource, dropDestination:DropDestination) {
        self.dragSource = dragSource
        self.dropDestination = dropDestination

        let originalTableBounds = dropDestination.destinationTableView.bounds
        let frame = CGRect(origin: CGPoint(x: 0, y: -dropDestination.destinationTableView.contentInset.top),
            size: originalTableBounds.size)
        
        cancelView = CancelView(frame: frame)
        
        super.init(tableView: dropDestination.destinationTableView)
        self.positionChangeUpdatesDataSource = false
        self.shouldHideSourceView = false
        self.snapshotScale = 0.9
        self.updateSnapshotXPosition = true
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
    
    override func getScrollingController() -> DragGestureScrollingController {
        return DragGestureScrollingController(scrollView: dropDestination.destinationTableView, delegate: self)
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
    
    override func gestureDidChange(sender: UIGestureRecognizer, newLocationInsideTableView: CGPoint?) {
        if newLocationInsideTableView == nil && !cancelViewVisible {
            cancelView.alpha = 0
            cancelViewVisible = true
            let tableView = dropDestination.destinationTableView
            tableView.addSubview(cancelView)
            cancelView.center.x = tableView.center.x
            cancelView.frame.origin.y = tableView.contentOffset.y + tableView.contentInset.top
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.cancelView.alpha = 1.0
            })
        } else if newLocationInsideTableView != nil && cancelViewVisible {
            removeCancelView()
        }
    }
    
    private func removeCancelView() {
        cancelView.alpha = 1.0
        cancelViewVisible = false
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.cancelView.alpha = 0.0
            }, completion: { (finished:Bool) -> Void in
                self.cancelView.removeFromSuperview()
        })
    }
    
    override func persistChanges(sender: UIGestureRecognizer) {
        if(cancelViewVisible) {
            removeCancelView()
        }
        let tableView = dropDestination.destinationTableView
        let location = sender.locationInView(tableView)
        let insideTableView = tableView.pointInside(location, withEvent: nil)
        let localItemsToInsert = itemsToDrag
        let localIndexPathForInserting = indexPathOfMovingItem
        
        tableView.deleteRowsAtIndexPaths([localIndexPathForInserting], withRowAnimation: .None)
        
        if(insideTableView) {
            if let itemsToInsert = localItemsToInsert {
                var indexPaths = [NSIndexPath]()
                let startingIndex = localIndexPathForInserting.row
                let noOfItemsToInsert = dropDestination.setDropItems(itemsToInsert, atIndex:localIndexPathForInserting)
                for index in startingIndex ..< (startingIndex + noOfItemsToInsert)  {
                    indexPaths.append(NSIndexPath(forRow: index, inSection: 0))
                }
                
                tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: noOfItemsToInsert == 1 ? .Fade : .Automatic)
            }
        }
    }
}

protocol DragSource {

    var sourceTableView:UITableView? { get }
    
    func getItemsToDrag(indexPath:NSIndexPath) -> [AudioTrack]?
    
}

protocol DropDestination {
    
    var indexPathOfMovingItem:NSIndexPath! { get set }
    
    var destinationTableView:UITableView { get }
    
    func setDropItems(dropItems:[AudioTrack], atIndex:NSIndexPath) -> Int
    
}