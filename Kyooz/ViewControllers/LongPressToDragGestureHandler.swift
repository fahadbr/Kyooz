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
    private lazy var dragGestureScrollingController:DragGestureScrollingController! = DragGestureScrollingController(scrollView: self.destinationTableView, delegate: self)

    private var beginningAnimationEnded = false
    private var gestureActivated = false

    var indexPathOfMovingItem:IndexPath! {
        didSet {
            wrapperDSD?.indexPathOfMovingItem = indexPathOfMovingItem
        }
    }
    var originalIndexPathOfMovingItem:IndexPath!
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
    
    final func handleGesture(_ sender: UILongPressGestureRecognizer) {
        let state:UIGestureRecognizerState = sender.state
        switch(state) {
        case .began:
            guard let sourceTableView = self.sourceTableView else { return }
            
            let location = sender.location(in: sourceTableView)
            guard let initialIndexPath = sourceTableView.indexPathForRow(at: location) else {
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
        case .changed:
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
                DispatchQueue.main.async { [weak self]() in
                    self?.handleGesture(sender)
                }
                return
            }
            
            #if MOCK_DATA
                if KyoozUtils.screenshotUITesting {
                    KyoozUtils.doInMainQueueAfterDelay(1) {
                        self.handleGesture(sender)
                    }
                    return
                }
            #endif
            
            gestureActivated = false
            dragGestureScrollingController.invalidateDisplayLink()
            dragGestureScrollingController = nil
            
            do {
                try wrapperDSD?.persistChanges()
            } catch let error {
                KyoozUtils.showPopupError(withTitle: "Couldn't Complete the Gesture", withThrownError: error, presentationVC: nil)
            }
            
            let cell = destinationTableView.cellForRow(at: indexPathOfMovingItem)
            removeSnapshotFromView(cell, viewToFadeOut: snapshotContainer, completionHandler: { (finished:Bool) -> Void in
                self.snapshotContainer.removeFromSuperview()
                self.gestureDidEnd(sender)
            })
        }
    }
    
    func createWrapperDSD(_ tableView: UITableView, sourceDSD:AudioEntityDSDProtocol, originalIndexPath:IndexPath) -> DragToRearrangeDSDWrapper? {
        return DragToRearrangeDSDWrapper(tableView: tableView, datasourceDelegate: sourceDSD, originalIndexPath: originalIndexPath)
    }
    
    func gestureDidBegin(_ sender:UIGestureRecognizer) {
        delegate?.gestureDidBegin?(sender)
        originalDSD = (destinationTableView.dataSource, destinationTableView.delegate)
        if let datasourceDelegate = destinationTableView.dataSource as? AudioEntityDSDProtocol {
            let wrapperDSD = createWrapperDSD(destinationTableView, sourceDSD:datasourceDelegate, originalIndexPath: originalIndexPathOfMovingItem)
            destinationTableView.dataSource = wrapperDSD
            destinationTableView.delegate = wrapperDSD
            self.wrapperDSD = wrapperDSD
        }
    }
    
    
    func gestureDidEnd(_ sender:UIGestureRecognizer) {
        delegate?.gestureDidEnd?(sender)
    }
    
    final func handlePositionChange(_ sender: UILongPressGestureRecognizer) -> CGPoint? {
        let location = sender.location(in: destinationTableView)
        locationInDestinationTableView = destinationTableView.point(inside: location, with: nil)
        
        updateSnapshotPosition(sender.location(in: sender.view))
        let point = locationInDestinationTableView ? location : CGPoint(x: 0, y: location.y)
        if let indexPath = destinationTableView.indexPathForRow(at: point) where indexPathOfMovingItem != indexPath {
            if let canMove = destinationTableView.dataSource?.tableView?(destinationTableView, canMoveRowAt: indexPathOfMovingItem) where canMove {
                destinationTableView.moveRow(at: indexPathOfMovingItem, to: indexPath)
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
    
    func getViewForSnapshot(_ sender:UIGestureRecognizer) -> UIView? {
        guard let indexPathOfMovingItem = self.indexPathOfMovingItem else { return nil }
        
        let cell = sourceTableView?.cellForRow(at: indexPathOfMovingItem)
        cell?.isHighlighted = false
        return cell
    }
    
    func createSnapshotFromView(_ viewForSnapshot:UIView, sender:UIGestureRecognizer) {
        viewForSnapshot.layer.masksToBounds = true
        viewForSnapshot.layer.cornerRadius = cornerRadiusForSnapshot
        
        snapshot = ImageUtils.customSnapshotFromView(viewForSnapshot)
        snapshotContainer = UIView(frame: snapshot.frame)
        snapshotContainer.addSubview(snapshot)
		
        viewForSnapshot.layer.masksToBounds = false
        
        //add the snapshot as a subview, centered at cell's center
        let locationInView = sender.location(in: sender.view)
//        updateSnapshotPosition(shouldHideSourceView ? viewForSnapshot.center : locationInView)
        let p = viewForSnapshot.convert(CGPoint(x: viewForSnapshot.bounds.midX, y: viewForSnapshot.bounds.midY), to: sender.view)
        updateSnapshotPosition(p)
        sender.view?.addSubview(snapshotContainer)
        beginningAnimationEnded = false
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            
            //Offest for gesture location
            self.updateSnapshotPosition(locationInView)
            self.snapshotContainer.transform = CGAffineTransform(scaleX: self.snapshotScale, y: self.snapshotScale)
            self.snapshot.alpha = 0.80
            self.snapshot.layer.shadowColor = UIColor.white.cgColor
            }, completion: {_ in
                if(self.shouldHideSourceView) {
                    viewForSnapshot.isHidden = true
                }
                self.beginningAnimationEnded = true
        } )

    }
    
    func removeSnapshotFromView(_ viewToFadeIn:UIView?, viewToFadeOut:UIView, completionHandler:(Bool)->()) {
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            if(viewToFadeIn != nil) {
                viewToFadeOut.center = viewToFadeIn!.center
                viewToFadeOut.transform = CGAffineTransform.identity
                viewToFadeOut.layer.shadowOpacity = 0
            } else {
                viewToFadeOut.alpha = 0.0
            }
        },completion: completionHandler)
    }
    
    final func updateSnapshotPosition(_ location:CGPoint) {
        if updateSnapshotXPosition {
            snapshotContainer.center = location
        } else {
            snapshotContainer.center.y = location.y
        }
    }
    
}
