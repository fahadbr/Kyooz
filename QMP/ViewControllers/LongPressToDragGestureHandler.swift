//
//  LongPressToDragGestureHandler.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

class LongPressToDragGestureHandler : NSObject, GestureHandler, TableViewScrollPositionControllerDelegate{
    
    private let tableView:UITableView
    
    private var snapshot:UIView!
    private var tableViewScrollPositionController:TableViewScrollPositionController!

    private var beginningAnimationEnded = false
    private var gestureActivated = false

    var indexPathOfMovingItem:NSIndexPath!
    var delegate:GestureHandlerDelegate?
    
    var positionChangeUpdatesDataSource = true
    var shouldHideSourceView = true
    
    init(tableView:UITableView) {
        self.tableView = tableView
    }
    
    func handleGesture(sender: UILongPressGestureRecognizer) {
        let state:UIGestureRecognizerState = sender.state
        
        switch(state) {
        case .Began:
            if let result = getCellForSnapshot(sender, tableView:tableView) {
                gestureActivated = true
                indexPathOfMovingItem = result.indexPath
                
                gestureDidBegin(sender)
                tableViewScrollPositionController = getTableViewScrollController()
                
                //take a snapshot of the selected row using a helper method
                createSnapshotFromView(result.cell, sender: sender)
            }
        case .Changed:
            if(!gestureActivated) { return }
            gestureDidChange(sender)
            if let location = handlePositionChange(sender) {
                tableViewScrollPositionController?.startScrollingWithLocation(location, gestureRecognizer: sender)
            }
        default:
            if(!gestureActivated) { return }
            
            if(!beginningAnimationEnded) {
                //if the beginning animation hasnt ended yet, we must wait until it is
                //so we call the method again to retry
                dispatch_async(dispatch_get_main_queue()) { [weak self]() in
                    self?.handleGesture(sender)
                }
                return
            }
            gestureActivated = false
            gestureDidEnd(sender)
            
            tableViewScrollPositionController?.invalidateTimer()
            tableViewScrollPositionController = nil
            
            let cell = tableView.cellForRowAtIndexPath(indexPathOfMovingItem)!
            removeSnapshotFromView(cell, viewToFadeOut: snapshot, completionHandler: { (finished:Bool) -> Void in
                self.snapshot.removeFromSuperview()
                self.snapshot = nil
                self.indexPathOfMovingItem = nil
            })
        }
    }
    
    func gestureDidBegin(sender:UIGestureRecognizer) {
        delegate?.gestureDidBegin?(sender)
    }
    
    func gestureDidChange(sender:UIGestureRecognizer) {
        delegate?.gestureDidChange?(sender)
    }
    
    func gestureDidEnd(sender:UIGestureRecognizer) {
         delegate?.gestureDidEnd?(sender)
    }
    
    func handlePositionChange(sender: UILongPressGestureRecognizer) -> CGPoint? {
        let location = sender.locationInView(tableView)
        let insideTableView = tableView.pointInside(location, withEvent: nil)
        if(insideTableView) {
            updateSnapshotPosition(snapshot, sender:sender, locationInDestinationTableView: location)
            let indexPath = tableView.indexPathForRowAtPoint(location)
            if(indexPath != nil && !indexPathOfMovingItem.isEqual(indexPath)) {
                if(positionChangeUpdatesDataSource) {
                    if let canMove = tableView.dataSource?.tableView?(tableView, canMoveRowAtIndexPath: indexPathOfMovingItem) {
                        if(canMove) {
                            tableView.dataSource?.tableView?(tableView, moveRowAtIndexPath: indexPathOfMovingItem, toIndexPath: indexPath!)
                        }
                    }
                }
                tableView.moveRowAtIndexPath(indexPathOfMovingItem, toIndexPath: indexPath!)
                indexPathOfMovingItem = indexPath!
            }
            return location
        } else {
            tableViewScrollPositionController?.invalidateTimer()
        }
        return nil
    }
    
    func getTableViewScrollController() -> TableViewScrollPositionController {
        return TableViewScrollPositionController(tableView: tableView, delegate: self)
    }
    
    func getCellForSnapshot(sender:UIGestureRecognizer, tableView:UITableView) -> (cell:UITableViewCell, indexPath:NSIndexPath)? {
        let location = sender.locationInView(tableView)
        if let indexPath = tableView.indexPathForRowAtPoint(location) {
            let cell = tableView.cellForRowAtIndexPath(indexPath)!
            cell.highlighted = false
            return (cell, indexPath)
        }
        return nil
    }
    
    func createSnapshotFromView(viewForSnapshot:UIView, sender:UIGestureRecognizer) {
        snapshot = ImageHelper.customSnapshotFromView(viewForSnapshot)
        
        //add the snapshot as a subview, centered at cell's center
        updateSnapshotPosition(snapshot, sender:sender, locationInDestinationTableView: viewForSnapshot.center)
        snapshot.alpha = 0.0
        sender.view?.addSubview(snapshot)
        beginningAnimationEnded = false
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            
            //Offest for gesture location
            self.updateSnapshotPosition(self.snapshot, sender: sender, locationInDestinationTableView: viewForSnapshot.center)
            self.snapshot.transform = CGAffineTransformMakeScale(1.10, 1.10)
            self.snapshot.alpha = 0.80
            
            if(self.shouldHideSourceView) {
                //Fade out the cell in the tableview
                viewForSnapshot.alpha = 0.0
            }
            }, completion: {(finished:Bool) in
                if(self.shouldHideSourceView) {
                    viewForSnapshot.hidden = true
                }
                self.beginningAnimationEnded = true
        } )

    }
    
    func removeSnapshotFromView(viewToFadeIn:UIView?, viewToFadeOut:UIView, completionHandler:(Bool)->()) {
        if(viewToFadeIn != nil) {
            viewToFadeIn!.hidden = false
            viewToFadeIn!.alpha = 0.0
        }
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            if(viewToFadeIn != nil) {
                viewToFadeOut.center = viewToFadeIn!.center
                viewToFadeOut.transform = CGAffineTransformIdentity
                //undo fade out
                viewToFadeIn!.alpha = 1.0
            }
            viewToFadeOut.alpha = 0.0
            },completion: completionHandler)
    }
    
    func updateSnapshotPosition(snapshot:UIView, sender:UIGestureRecognizer, locationInDestinationTableView:CGPoint) {
        snapshot.center.y = locationInDestinationTableView.y
    }
    
}
