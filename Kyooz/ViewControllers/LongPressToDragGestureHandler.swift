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
    private let destinationTableView:UITableView
    
    private (set) var snapshotContainer:UIView!
    private (set) var snapshot:UIView!
    private lazy var dragGestureScrollingController:DragGestureScrollingController = DragGestureScrollingController(scrollView: self.destinationTableView, delegate: self)

    private var beginningAnimationEnded = false
    private var gestureActivated = false

    var indexPathOfMovingItem:NSIndexPath! {
        didSet {
            wrapperDSD?.indexPathOfMovingItem = indexPathOfMovingItem
        }
    }
    var originalIndexPathOfMovingItem:NSIndexPath!
    var delegate:GestureHandlerDelegate?
    
    var shouldHideSourceView = true
    var updateSnapshotXPosition = false
    
    var snapshotScale:CGFloat = 1.10
    var cornerRadiusForSnapshot:CGFloat = 0
    
    private var originalDSD:(UITableViewDataSource?, UITableViewDelegate?)!
    private (set) var wrapperDSD:DragToRearrangeDSDWrapper?
    
    var locationInDestinationTableView = true
    
    convenience init(tableView:UITableView) {
        self.init(sourceTableView:tableView, destinationTableView: tableView)
    }
    
    init(sourceTableView:UITableView?, destinationTableView:UITableView) {
        self.sourceTableView = sourceTableView
        self.destinationTableView = destinationTableView
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
            
            //take a snapshot of the selected row using a helper method
            createSnapshotFromView(viewForSnapshot, sender: sender)
            gestureDidBegin(sender)
            gestureActivated = wrapperDSD != nil
        case .Changed:
            if(!gestureActivated) { return }
            let location = handlePositionChange(sender)
            if let locationInsideTableView = location {
                dragGestureScrollingController.startScrollingWithLocation(locationInsideTableView, gestureRecognizer: sender)
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
            
            do {
                try wrapperDSD?.persistChanges()
            } catch let error {
                KyoozUtils.showPopupError(withTitle: "Couldn't Complete the Gesture", withThrownError: error, presentationVC: nil)
            }
            
            let cell = destinationTableView.cellForRowAtIndexPath(indexPathOfMovingItem)
            removeSnapshotFromView(cell, viewToFadeOut: snapshotContainer, completionHandler: { (finished:Bool) -> Void in
                self.snapshotContainer.removeFromSuperview()
                self.gestureDidEnd(sender)
            })
        }
    }
    
    func createWrapperDSD(tableView: UITableView, sourceDSD:AudioEntityDSDProtocol, originalIndexPath:NSIndexPath) -> DragToRearrangeDSDWrapper? {
        return DragToRearrangeDSDWrapper(tableView: tableView, datasourceDelegate: sourceDSD, originalIndexPath: originalIndexPath)
    }
    
    func gestureDidBegin(sender:UIGestureRecognizer) {
        delegate?.gestureDidBegin?(sender)
        originalDSD = (destinationTableView.dataSource, destinationTableView.delegate)
        if let datasourceDelegate = destinationTableView.dataSource as? AudioEntityDSDProtocol {
            let wrapperDSD = createWrapperDSD(destinationTableView, sourceDSD:datasourceDelegate, originalIndexPath: originalIndexPathOfMovingItem)
            destinationTableView.dataSource = wrapperDSD
            destinationTableView.delegate = wrapperDSD
            self.wrapperDSD = wrapperDSD
        }
    }
    
    
    func gestureDidEnd(sender:UIGestureRecognizer) {
        delegate?.gestureDidEnd?(sender)
    }
    
    final func handlePositionChange(sender: UILongPressGestureRecognizer) -> CGPoint? {
        let location = sender.locationInView(destinationTableView)
        locationInDestinationTableView = destinationTableView.pointInside(location, withEvent: nil)
        
        updateSnapshotPosition(sender.locationInView(sender.view))
        let point = locationInDestinationTableView ? location : CGPoint(x: 0, y: location.y)
        if let indexPath = destinationTableView.indexPathForRowAtPoint(point) where indexPathOfMovingItem != indexPath {
            if let canMove = destinationTableView.dataSource?.tableView?(destinationTableView, canMoveRowAtIndexPath: indexPathOfMovingItem) where canMove {
                destinationTableView.moveRowAtIndexPath(indexPathOfMovingItem, toIndexPath: indexPath)
                indexPathOfMovingItem = indexPath
            }
        }
        if(locationInDestinationTableView) {
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
        snapshotContainer = UIView(frame: snapshot.frame)
        snapshotContainer.addSubview(snapshot)
        //TODO: set the original position for the snapshot container?
		
        viewForSnapshot.layer.masksToBounds = false
        
        //add the snapshot as a subview, centered at cell's center
        let locationInView = sender.locationInView(sender.view)
//        updateSnapshotPosition(shouldHideSourceView ? viewForSnapshot.center : locationInView)
        let p = viewForSnapshot.convertPoint(CGPoint(x: viewForSnapshot.bounds.midX, y: viewForSnapshot.bounds.midY), toView: sender.view)
        updateSnapshotPosition(p)
        sender.view?.addSubview(snapshotContainer)
        beginningAnimationEnded = false
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            
            //Offest for gesture location
            self.updateSnapshotPosition(locationInView)
            self.snapshotContainer.transform = CGAffineTransformMakeScale(self.snapshotScale, self.snapshotScale)
            self.snapshot.alpha = 0.80
            self.snapshot.layer.shadowColor = UIColor.whiteColor().CGColor
            }, completion: {_ in
                if(self.shouldHideSourceView) {
                    viewForSnapshot.hidden = true
                }
                self.beginningAnimationEnded = true
        } )

    }
    
    func removeSnapshotFromView(viewToFadeIn:UIView?, viewToFadeOut:UIView, completionHandler:(Bool)->()) {
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            if(viewToFadeIn != nil) {
                viewToFadeOut.center = viewToFadeIn!.center
                viewToFadeOut.transform = CGAffineTransformIdentity
                viewToFadeOut.layer.shadowOpacity = 0
            } else {
                viewToFadeOut.alpha = 0.0
            }
        },completion: completionHandler)
    }
    
    final func updateSnapshotPosition(location:CGPoint) {
        if updateSnapshotXPosition {
            snapshotContainer.center = location
        } else {
            snapshotContainer.center.y = location.y
        }
    }
    
}
