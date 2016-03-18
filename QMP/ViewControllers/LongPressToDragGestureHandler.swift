//
//  LongPressToDragGestureHandler.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

class LongPressToDragGestureHandler : NSObject, GestureHandler{
    
    private let sourceTableView:UITableView?
    private let tableView:UITableView
    
    private var snapshot:UIView!
    private var snapshotLayer:CALayer!
    private lazy var dragGestureScrollingController:DragGestureScrollingController = DragGestureScrollingController(scrollView: self.tableView, delegate: self)

    private var beginningAnimationEnded = false
    private var gestureActivated = false

    var indexPathOfMovingItem:NSIndexPath!
    var originalIndexPathOfMovingItem:NSIndexPath!
    var delegate:GestureHandlerDelegate?
    
    var shouldHideSourceView = true
    var updateSnapshotXPosition = false
    
    var snapshotScale:CGFloat = 1.10
    var cornerRadiusForSnapshot:CGFloat = 0
    
    convenience init(tableView:UITableView) {
        self.init(sourceTableView:tableView, destinationTableView: tableView)
    }
    
    init(sourceTableView:UITableView?, destinationTableView:UITableView) {
        self.sourceTableView = sourceTableView
        self.tableView = destinationTableView
    }
    
    
    deinit {
        Logger.debug("deinitializing long press to drag gesture handler")
    }
    
    final func handleGesture(sender: UILongPressGestureRecognizer) {
        let state:UIGestureRecognizerState = sender.state

        switch(state) {
        case .Began:
            guard let sourceTableView = self.sourceTableView else { return }
            
            let location = sender.locationInView(sourceTableView)
            guard let initialIndexPath = sourceTableView.indexPathForRowAtPoint(location) else {
                return
            }
            indexPathOfMovingItem = initialIndexPath
            originalIndexPathOfMovingItem = initialIndexPath
            guard let viewForSnapshot = getViewForSnapshot(sender) else {
                return
            }
            gestureActivated = true
            gestureDidBegin(sender)
            
            //take a snapshot of the selected row using a helper method
            createSnapshotFromView(viewForSnapshot, sender: sender)
        case .Changed:
            if(!gestureActivated) { return }
            let location = handlePositionChange(sender)
            if let locationInsideTableView = location {
                dragGestureScrollingController.startScrollingWithLocation(locationInsideTableView, gestureRecognizer: sender)
            }
            gestureDidChange(sender, newLocationInsideTableView: location)
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
            
            let cell = tableView.cellForRowAtIndexPath(indexPathOfMovingItem)
            removeSnapshotFromView(cell, viewToFadeOut: snapshot, completionHandler: { (finished:Bool) -> Void in
                self.snapshot.removeFromSuperview()
                self.indexPathOfMovingItem = nil
            })
        }
    }
    
    func gestureDidBegin(sender:UIGestureRecognizer) {
        delegate?.gestureDidBegin?(sender)
    }
    
    func gestureDidChange(sender:UIGestureRecognizer, newLocationInsideTableView:CGPoint?) {
        
    }
    
    func gestureDidEnd(sender:UIGestureRecognizer) {
        delegate?.gestureDidEnd?(sender)
        persistChanges(sender)
    }
    
    func persistChanges(sender:UIGestureRecognizer) {
        if !originalIndexPathOfMovingItem.isEqual(indexPathOfMovingItem) {
            tableView.dataSource?.tableView?(tableView, moveRowAtIndexPath: originalIndexPathOfMovingItem, toIndexPath: indexPathOfMovingItem)
        }
    }
    
    final func handlePositionChange(sender: UILongPressGestureRecognizer) -> CGPoint? {
        let location = sender.locationInView(tableView)
        let insideTableView = tableView.pointInside(location, withEvent: nil)
        
        updateSnapshotPosition(sender.locationInView(sender.view))
        let point = insideTableView ? location : CGPoint(x: 0, y: location.y)
        if let indexPath = tableView.indexPathForRowAtPoint(point) where !indexPathOfMovingItem.isEqual(indexPath) {
            if let canMove = tableView.dataSource?.tableView?(tableView, canMoveRowAtIndexPath: indexPathOfMovingItem) where canMove {
                tableView.moveRowAtIndexPath(indexPathOfMovingItem, toIndexPath: indexPath)
                indexPathOfMovingItem = indexPath
            }
        }
        if(insideTableView) {
            return location
        } else {
            dragGestureScrollingController.invalidateDisplayLink()
            return nil
        }
    }
    
    func getViewForSnapshot(sender:UIGestureRecognizer) -> UIView? {
        guard let indexPathOfMovingItem = self.indexPathOfMovingItem else { return nil }
        
        let cell = sourceTableView?.cellForRowAtIndexPath(indexPathOfMovingItem)
        cell?.highlighted = false
        return cell
    }
    
    func createSnapshotFromView(viewForSnapshot:UIView, sender:UIGestureRecognizer) {
        viewForSnapshot.layer.masksToBounds = true
        viewForSnapshot.layer.cornerRadius = cornerRadiusForSnapshot
        snapshot = ImageHelper.customSnapshotFromView(viewForSnapshot)
        
        //add the snapshot as a subview, centered at cell's center
        let locationInView = sender.locationInView(sender.view)
        updateSnapshotPosition(locationInView)
        sender.view?.addSubview(snapshot)
        beginningAnimationEnded = false
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            
            //Offest for gesture location
            self.updateSnapshotPosition(locationInView)
            self.snapshot.transform = CGAffineTransformMakeScale(self.snapshotScale, self.snapshotScale)
            self.snapshot.alpha = 0.80
            self.snapshot.layer.shadowColor = UIColor.whiteColor().CGColor

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
    
    final func updateSnapshotPosition(location:CGPoint) {
        if updateSnapshotXPosition {
            snapshot.center = location
        } else {
            snapshot.center.y = location.y
        }
    }
    
}
