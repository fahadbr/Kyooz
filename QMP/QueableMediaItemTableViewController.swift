//
//  QueableMediaItemTableViewController.swift
//  QMP
//
//  Created by FAHAD RIAZ on 5/9/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class QueableMediaItemTableViewController: UITableViewController  {
    
    var containerViewController = ContainerViewController.instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Logger.debug("adding long press gesture for \(title) view controller")
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPressGesture:")
//        longPressGestureRecognizer.cancelsTouchesInView = true
//        longPressGestureRecognizer.delegate = self
        tableView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    func handleLongPressGesture(sender:UILongPressGestureRecognizer) {
        let state:UIGestureRecognizerState = sender.state
        let location = sender.locationInView(tableView)
        let indexPath:NSIndexPath? = tableView.indexPathForRowAtPoint(location)
        
        //since we're looking up the index path from a point location on the screen
        //send by the gesture recognizer, the indexPath may possibly be nil
        if(indexPath == nil) { return }
        
        let mediaItems = getMediaItemsForIndexPath(indexPath!)
        containerViewController.addSidePanelViewController()
        containerViewController.animateSidePanel(shouldExpand: true)
        containerViewController.nowPlayingViewController?.itemsToInsert = mediaItems
        containerViewController.nowPlayingViewController?.insertMode = true
    }
    
    func getMediaItemsForIndexPath(indexPath:NSIndexPath) -> [MPMediaItem] {
        fatalError("This method needs to be implemented by a subclass")
    }
    

//    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        if(otherGestureRecognizer == longPressGestureRecognizer) {
//            return true
//        }
//        return false
//    }
//    
//    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        if(gestureRecognizer == longPressGestureRecognizer) {
//            return true
//        }
//        return false
//    }

    

}
