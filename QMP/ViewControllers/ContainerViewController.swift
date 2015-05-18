//
//  ContainerViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/15/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class ContainerViewController : UIViewController , GestureHandlerDelegate {
    
    static let instance:ContainerViewController = ContainerViewController()
    
    private let centerPanelExpandedOffset:CGFloat = 60
    private let timeDelayInNanoSeconds = Int64(0.50 * Double(NSEC_PER_SEC))
    
    var longPressGestureRecognizer:UILongPressGestureRecognizer!
    var dragAndDropHandler:LongPressDragAndDropGestureHandler!
    
    var tapGestureRecognizer:UITapGestureRecognizer!
    var panGestureRecognizer:UIPanGestureRecognizer!
    var screenEdgePanGestureRecognizer:UIScreenEdgePanGestureRecognizer!
    
    var rootViewController:RootViewController!
    
    var nowPlayingNavigationController:UINavigationController?
    var nowPlayingViewController:NowPlayingViewController?
    
    var sidePanelExpanded:Bool = false {
        didSet {
            showShadowForCenterViewController(sidePanelExpanded)
            for gestureRecognizerObject in rootViewController.view.gestureRecognizers! {
                let gestureRecognizer = gestureRecognizerObject as! UIGestureRecognizer
                if(gestureRecognizer == tapGestureRecognizer || gestureRecognizer == panGestureRecognizer) {
                    gestureRecognizer.enabled = sidePanelExpanded
                } else {
                    gestureRecognizer.enabled = !sidePanelExpanded
                }
            }
            rootViewController.enableGesturesInSubViews(shouldEnable: !sidePanelExpanded)
            nowPlayingViewController?.viewExpanded = sidePanelExpanded
        }
    }
    
    deinit {
        unregisterForNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForNotifications()
        
        self.rootViewController = RootViewController.instance
        
        self.view.addSubview(rootViewController.view)
        self.addChildViewController(rootViewController)
        self.rootViewController.didMoveToParentViewController(self)
        self.rootViewController.gestureDelegate = self
        
        self.screenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "handleScreenEdgePanGesture:")
        self.screenEdgePanGestureRecognizer.edges = UIRectEdge.Right
        self.screenEdgePanGestureRecognizer.delegate = self
        self.rootViewController.view.addGestureRecognizer(self.screenEdgePanGestureRecognizer)

        //keep a reference of this gesture recogizer to enable/disable it
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTouchGesture:")
        self.tapGestureRecognizer.enabled = sidePanelExpanded
        self.rootViewController.view.addGestureRecognizer(tapGestureRecognizer)
        
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        self.panGestureRecognizer.enabled = sidePanelExpanded
        self.rootViewController.view.addGestureRecognizer(panGestureRecognizer)
        
        addSidePanelViewController()
        dragAndDropHandler = LongPressDragAndDropGestureHandler(dragSource: rootViewController, dropDestination: nowPlayingViewController!)
        dragAndDropHandler.delegate = self
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: dragAndDropHandler, action: "handleGesture:")
        longPressGestureRecognizer.delegate = self
        view.addGestureRecognizer(longPressGestureRecognizer)
        
    }
    
    func toggleSidePanel() {
        if(!sidePanelExpanded) {
            self.addSidePanelViewController()
        }
        animateSidePanel(shouldExpand: !sidePanelExpanded)
    }
    
    func showShadowForCenterViewController(shouldShowShadow:Bool) {
        if(shouldShowShadow) {
            self.rootViewController.view.layer.shadowOpacity = 0.8
        } else {
            self.rootViewController.view.layer.shadowOpacity = 0.0
        }
    }
    
    func addSidePanelViewController() {
        if(nowPlayingViewController == nil) {
            nowPlayingViewController = UIStoryboard.nowPlayingViewController()
            
            let originalFrame = nowPlayingViewController!.view.bounds
            let newWidth = CGRectGetWidth(self.view.bounds) - centerPanelExpandedOffset
            let newHeight = originalFrame.height
            let newX = originalFrame.origin.x + centerPanelExpandedOffset
            let newY = originalFrame.origin.y
            
//            nowPlayingViewController!.view.frame = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
            nowPlayingNavigationController = UINavigationController(rootViewController: nowPlayingViewController!)
            nowPlayingNavigationController!.view.frame = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
            nowPlayingNavigationController!.toolbarHidden = false
            view.insertSubview(nowPlayingNavigationController!.view, atIndex: 0)
            addChildViewController(nowPlayingNavigationController!)
            nowPlayingNavigationController!.didMoveToParentViewController(self)
        }
    }
    
    func animateSidePanel(#shouldExpand: Bool) {
        if(shouldExpand) {
            sidePanelExpanded = true
            
            animateCenterPanelXPosition(targetPosition: -CGRectGetWidth(rootViewController.view.frame) +
                centerPanelExpandedOffset)
            
        } else {
            animateCenterPanelXPosition(targetPosition: 0) { finished in
                self.sidePanelExpanded = false
            }
        }
    }
    
    func animateCenterPanelXPosition(#targetPosition:CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: .CurveEaseInOut,
            animations: {self.rootViewController.view.frame.origin.x = targetPosition},
            completion: completion)
        
    }
    
    func deinitializeSideViewController(notification:NSNotification) {
//        if(!sidePanelExpanded && self.nowPlayingViewController != nil) {
//            Logger.debug("deinitializing side view controller")
//            nowPlayingNavigationController!.view.removeFromSuperview()
//            nowPlayingViewController = nil
//            nowPlayingNavigationController = nil
//        }
    }
    
    func presentSettingsViewController() {
        animateSidePanel(shouldExpand: false)
        rootViewController.presentSettingsViewController()
    }
    

    
    //MARK: NOTIFICATION REGISTRATIONS
    
    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let application = UIApplication.sharedApplication()
        
        notificationCenter.addObserver(self, selector: "deinitializeSideViewController:",
            name: UIApplicationDidEnterBackgroundNotification, object: application)
        notificationCenter.addObserver(self, selector: "deinitializeSideViewController:",
            name: UIApplicationWillResignActiveNotification, object: application)
        notificationCenter.addObserver(self, selector: "deinitializeSideViewController:",
            name: UIApplicationWillTerminateNotification, object: application)
        notificationCenter.addObserver(self, selector: "deinitializeSideViewController:",
            name: UIApplicationDidReceiveMemoryWarningNotification, object: application)
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}

extension ContainerViewController : UIGestureRecognizerDelegate {
    // MARK: Gesture recognizer
    
    func handleTouchGesture(recognizer:UITapGestureRecognizer) {
        if(recognizer.state == .Ended) {
            self.toggleSidePanel()
        }
    }
    
    func handleScreenEdgePanGesture(recognizer: UIPanGestureRecognizer) {
        let gestureIsDraggingFromLeftToRight = (recognizer.velocityInView(view).x > 0)
        
        
        switch(recognizer.state) {
        case .Began:
            Logger.debug("NPVC Screen Edge Pan Gesture Began")
            if(!sidePanelExpanded && !gestureIsDraggingFromLeftToRight) {
                addSidePanelViewController()
            }
            
            showShadowForCenterViewController(true)
        case .Changed:
            recognizer.view!.center.x = recognizer.view!.center.x + recognizer.translationInView(view).x
            recognizer.setTranslation(CGPointZero, inView: view)
        case .Ended, .Cancelled:
            if(nowPlayingViewController != nil) {
                let hasMovedEnoughLeftOfCenter = recognizer.view!.center.x < (self.view.center.x * 0.90)
                animateSidePanel(shouldExpand: hasMovedEnoughLeftOfCenter)
            }
        default:
            break
        }
        
    }
    
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let gestureIsDraggingFromLeftToRight = (recognizer.velocityInView(view).x > 0)
        
        switch(recognizer.state) {
        case .Changed:
            recognizer.view!.center.x = recognizer.view!.center.x + recognizer.translationInView(view).x
            recognizer.setTranslation(CGPointZero, inView: view)
        case .Ended, .Cancelled:
            if(nowPlayingViewController != nil) {
                let hasMovedEnoughRightOfScreenEdge = recognizer.view!.center.x < -(self.view.center.x * 0.90)
                animateSidePanel(shouldExpand: hasMovedEnoughRightOfScreenEdge)
            }
        default:
            break
        }
        
    }

    
    //MARK: INSERT MODE DELEGATION METHODS

    func gestureDidBegin(sender: UIGestureRecognizer) {
        if(sender == longPressGestureRecognizer) {
            addSidePanelViewController()
            animateSidePanel(shouldExpand: true)
            if(!nowPlayingViewController!.laidOutSubviews) {
                dispatch_async(dispatch_get_main_queue()) { self.gestureDidBegin(sender) }
                return
            }
            nowPlayingViewController!.insertMode = true
        }
    }
    
    func gestureDidEnd(sender: UIGestureRecognizer) {
        nowPlayingViewController!.insertMode = false
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeDelayInNanoSeconds), dispatch_get_main_queue()) { [unowned self]() in
            Logger.debug("ending insert mode and clearing data")
            self.animateSidePanel(shouldExpand: false)
        }
    }
    
//    func handleLongPressGesture(sender:UILongPressGestureRecognizer) {
//        let state:UIGestureRecognizerState = sender.state
//
//        
//        
//        //since we're looking up the index path from a point location on the screen
//        //send by the gesture recognizer, the indexPath may possibly be nil
//        switch(state) {
//        case .Began:
//            let tableView = UITableView()
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
//                    })
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
//                    self?.snapshot.alpha = 0.0
//                    }, completion: {[weak self](finished:Bool) in
//                        self?.snapshot.removeFromSuperview()
//                        self?.snapshot = nil
//
//                    })
//                containerViewController.endInsertMode(sender)
//            }
//        }
//        
//        
//    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(gestureRecognizer.isEqual(longPressGestureRecognizer)) {
            return !rootViewController.pullableViewExpanded
        }
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if(gestureRecognizer.isEqual(self.rootViewController.nowPlayingPanGestureRecognizer) &&
            otherGestureRecognizer.isEqual(self.screenEdgePanGestureRecognizer)) {
                Logger.debug("Mandating screenEdgePanGestureRecognizer to fail")
                return true
        }
        return false
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if(gestureRecognizer.isEqual(self.screenEdgePanGestureRecognizer) &&
            otherGestureRecognizer.isEqual(self.rootViewController.nowPlayingPanGestureRecognizer)) {
                Logger.debug("Mandating screenEdgePanGestureRecognizer to fail")
                return true
        }
        return false
    }
   
}
