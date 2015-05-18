//
//  QueableMediaItemTableViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/9/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class MediaItemTableViewController: UITableViewController  {
    
    var containerViewController = ContainerViewController.instance
//    var longPressGestureRecognizer:UILongPressGestureRecognizer!
//    var gestureActivated = false
    
    //MARK: gesture properties
    var snapshot:UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPressGesture:")
//        containerViewController.view.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    deinit {
        Logger.debug("removing gesture recognizer from container view for \(title) view controller")
//        containerViewController.view.removeGestureRecognizer(longPressGestureRecognizer)
    }
    
//    func handleLongPressGesture(sender:UILongPressGestureRecognizer) {
//        if(RootViewController.instance.pullableViewExpanded) { return }
//        let containerView = containerViewController.view
//        let state:UIGestureRecognizerState = sender.state
//        let location = sender.locationInView(containerView)
//        
//        
//        //since we're looking up the index path from a point location on the screen
//        //send by the gesture recognizer, the indexPath may possibly be nil
//        switch(state) {
//        case .Began:
//            let locationInSourceTable = sender.locationInView(tableView)
//            let indexPath:NSIndexPath? = tableView.indexPathForRowAtPoint(locationInSourceTable)
//            
//            if let sourceIndexPath = indexPath {
//                gestureActivated = true
//                let cell = tableView.cellForRowAtIndexPath(sourceIndexPath)!
//                cell.highlighted = false
//                
//                snapshot = ImageHelper.customSnapshotFromView(cell)
//                snapshot.center = location
//                snapshot.alpha = 0.0
//                
//                containerView.addSubview(snapshot)
//                let mediaItems = self.getMediaItemsForIndexPath(sourceIndexPath)
//                self.containerViewController.showNowPlayingControllerInsertMode(mediaItems, sender:sender)
//                UIView.animateWithDuration(0.25, animations: { [unowned self]() -> Void in
//                    self.snapshot.center = location
//                    self.snapshot.transform = CGAffineTransformMakeScale(1.10, 1.10)
//                    self.snapshot.alpha = 0.90
//                })
//            }
//        case .Changed:
//            if(gestureActivated) {
//                snapshot?.center = location
//                containerViewController.handleInsertPositionChanged(sender)
//            }
//        default:
//            if(gestureActivated) {
//                gestureActivated = false
//                UIView.animateWithDuration(0.25, animations: { [weak self]() -> Void in
//                        self?.snapshot.alpha = 0.0
//                    }, completion: {[weak self](finished:Bool) in
//                        self?.snapshot = nil
//                    })
//                containerViewController.endInsertMode(sender)
//            }
//        }
//        
//        
//    }
    
    func getMediaItemsForIndexPath(indexPath:NSIndexPath) -> [MPMediaItem] {
        fatalError("This method needs to be implemented by a subclass")
    }
    

    

}
