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


final class LongPressDragAndDropGestureHandler : LongPressToDragGestureHandler, CAAnimationDelegate {
    
    private var dragSource:DragSource
    private var dropDestination:DropDestination
    
    private var cancelViewVisible:Bool = false
    
    private lazy var cancelView:CancelView = CancelView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 100, height: 100)))
    
    private lazy var redLayer:CALayer = {
        let layer = CALayer()
        layer.frame = CGRect(origin: CGPoint.zero, size: self.snapshot?.bounds.size ?? CGSize.zero)
        layer.cornerRadius = self.cornerRadiusForSnapshot
        layer.backgroundColor = UIColor.red.cgColor
        layer.opacity = 0.3
        return layer
    }()
    
    override var locationInDestinationTableView:Bool {
        didSet {
            (wrapperDSD as? DragToInsertDSDWrapper)?.locationInDestinationTableView = locationInDestinationTableView
            if locationInDestinationTableView {
                removeCancelView()
            } else {
                showCancelView()
            }
        }
    }

    
    init(dragSource:DragSource, dropDestination:DropDestination) {
        self.dragSource = dragSource
        self.dropDestination = dropDestination
        
        super.init(sourceTableView: dragSource.sourceTableView, destinationTableView: dropDestination.destinationTableView)

        shouldHideSourceView = false
        snapshotScale = 0.85
        updateSnapshotXPosition = true
        cornerRadiusForSnapshot = 10
    }
    
    override func removeSnapshotFromView(_ viewToFadeIn:UIView?, viewToFadeOut:UIView, completionHandler:@escaping (Bool)->()) {
        guard locationInDestinationTableView else {
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                viewToFadeOut.alpha = 0.0
            }, completion: completionHandler)
            return
        }
        
        let newPosition = viewToFadeIn?.convert(CGPoint(x: viewToFadeIn!.bounds.midX, y: viewToFadeIn!.bounds.midY), to: viewToFadeOut.superview)
        UIView.animate(withDuration: 0.15, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
            if(newPosition != nil) {
                viewToFadeOut.center = newPosition!
            }
            viewToFadeOut.layer.shadowOpacity = 0
            viewToFadeOut.alpha = 0.5
            }, completion: completionHandler)
        
    }
    
    override func gestureDidBegin(_ sender: UIGestureRecognizer) {
        super.gestureDidBegin(sender)

        let tableView = dropDestination.destinationTableView
        let location = sender.location(in: tableView)
        let destinationIndexPath = tableView.indexPathForRow(at: CGPoint(x: 0, y: location.y)) ?? IndexPath(row: tableView.dataSource!.tableView(tableView, numberOfRowsInSection: 0) - 1, section: 0)
        indexPathOfMovingItem = destinationIndexPath

        tableView.insertRows(at: [destinationIndexPath], with: UITableViewRowAnimation.automatic)
    }
    
    override func createWrapperDSD(_ tableView:UITableView, sourceDSD:AudioEntityDSDProtocol, originalIndexPath:IndexPath) -> DragToRearrangeDSDWrapper? {
        guard let entities = dragSource.getSourceData()?.getTracksAtIndex(originalIndexPath) else {
            return nil
        }
        return DragToInsertDSDWrapper(tableView: tableView, datasourceDelegate: sourceDSD, originalIndexPath: originalIndexPath, entitiesToInsert: entities)
    }
    
    private func showCancelView() {
        guard !cancelViewVisible else { return }
        cancelView.center = CGPoint(x: snapshot.center.x, y: snapshot.center.y - 90)
        snapshotContainer.addSubview(cancelView)
        snapshot.layer.addSublayer(redLayer)
        
        cancelView.layer.add(getScaleAnimation(forShrinking: false, scale: 0.01), forKey: nil)
        snapshot.layer.add(getScaleAnimation(forShrinking: true, scale: 0.5), forKey: nil)
        
        cancelViewVisible = true
    }
    
    private func removeCancelView() {
        guard cancelViewVisible else { return }
        redLayer.removeFromSuperlayer()
        
        let shrinkAnimation = getScaleAnimation(forShrinking: true, scale: 0.01)
        shrinkAnimation.delegate = self
        
        cancelView.layer.add(shrinkAnimation, forKey: nil)
        snapshot.layer.add(getScaleAnimation(forShrinking: false, scale: 0.5), forKey: nil)
        cancelViewVisible = false
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        cancelView.removeFromSuperview()
        cancelView.layer.removeAllAnimations()
        snapshot.layer.removeAllAnimations()
    }
    
    private func getScaleAnimation(forShrinking animationIsToShrink:Bool, scale:CGFloat) -> CAAnimation {
        let animation = CABasicAnimation(keyPath: "transform")
        animation.duration = 0.20
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        let smallValue = NSValue(caTransform3D: CATransform3DMakeScale(scale, scale, scale))
        let fullValue = NSValue(caTransform3D: CATransform3DIdentity)
        
        if animationIsToShrink {
            animation.fromValue = fullValue
            animation.toValue = smallValue
        } else {
            animation.fromValue = smallValue
            animation.toValue = fullValue
        }

        animation.fillMode = kCAFillModeBoth
        animation.isRemovedOnCompletion = false
        return animation
    }
}

protocol DragSource {

    var sourceTableView:UITableView? { get }
    
    func getSourceData() -> AudioEntitySourceData?
    
}

protocol DropDestination {
    
    var destinationTableView:UITableView { get }
    
    func setDropItems(_ dropItems:[AudioTrack], atIndex:IndexPath) -> Int
    
}
