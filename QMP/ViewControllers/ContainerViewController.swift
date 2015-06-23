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
    private var centerPanelExpandedXPosition:CGFloat!
    
    var longPressGestureRecognizer:UILongPressGestureRecognizer!
    var dragAndDropHandler:LongPressDragAndDropGestureHandler!
    
    var tapGestureRecognizer:UITapGestureRecognizer!
    var panGestureRecognizer:UIPanGestureRecognizer!
    var screenEdgePanGestureRecognizer:UIScreenEdgePanGestureRecognizer!
    
    var rootViewController:RootViewController! {
        didSet {
            if rootViewController == nil { return }
            centerPanelExpandedXPosition = -CGRectGetWidth(rootViewController.view.frame) + centerPanelExpandedOffset
        }
    }
    
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
        

        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPressGesture:")
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
            let newX:CGFloat = CGRectGetWidth(view.bounds)
            let newY:CGFloat = 0.0
            
            nowPlayingNavigationController = UINavigationController(rootViewController: nowPlayingViewController!)
            nowPlayingNavigationController!.view.frame = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
            nowPlayingNavigationController!.toolbarHidden = false
            view.insertSubview(nowPlayingNavigationController!.view, atIndex: 0)
            addChildViewController(nowPlayingNavigationController!)
            nowPlayingNavigationController!.didMoveToParentViewController(self)
            
            nowPlayingNavigationController!.view.layer.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        }
    }
    
    func animateSidePanel(#shouldExpand: Bool) {
        if(shouldExpand) {
            sidePanelExpanded = true
            
            animateCenterPanelXPosition(targetPosition: -CGRectGetWidth(rootViewController.view.frame) +
                centerPanelExpandedOffset) { finished in Logger.debug("\(self.nowPlayingNavigationController!.view.frame.origin.x)") }
            
        } else {
            animateCenterPanelXPosition(targetPosition: 0) { finished in
                self.sidePanelExpanded = false
                Logger.debug("\(self.nowPlayingNavigationController!.view.frame.origin.x)")
            }
        }
    }
    
    private func transformForFraction(fraction:CGFloat) -> CATransform3D{
        var identity = CATransform3DIdentity
        identity.m34 = -1.0/1000
        let angle = Double(1.0 - fraction) * M_PI_2
        let xOffset = CGRectGetWidth(nowPlayingNavigationController!.view.bounds) * 0.5
        
        let rotateTransform = CATransform3DRotate(identity, CGFloat(angle), 0.0, 1.0, 0.0)

        let translateTransform = CATransform3DMakeTranslation(-xOffset, 0.0, 0.0)
        return CATransform3DConcat(rotateTransform, translateTransform)
    }
    
    func animateCenterPanelXPosition(#targetPosition:CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: .CurveEaseInOut,
            animations: {
                self.rootViewController.view.frame.origin.x = targetPosition
                let fraction:CGFloat = (targetPosition - self.view.frame.origin.x)/self.centerPanelExpandedXPosition
                self.nowPlayingNavigationController?.view.layer.transform = self.transformForFraction(fraction)
                self.nowPlayingNavigationController?.view.frame.origin.x = CGRectGetWidth(self.rootViewController.view.frame) + targetPosition
            },
            completion: completion)
        
    }
    
    func deinitializeSideViewController(notification:NSNotification) {
        if(!sidePanelExpanded && self.nowPlayingViewController != nil) {
            Logger.debug("deinitializing side view controller")
            nowPlayingNavigationController!.view.removeFromSuperview()
            nowPlayingViewController = nil
            nowPlayingNavigationController = nil
        }
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
            applyTranslationToViews(recognizer)
        case .Ended, .Cancelled:
            if(nowPlayingViewController != nil) {
                let hasMovedEnoughLeftOfCenter = recognizer.view!.center.x < (self.view.center.x * 0.90)
                animateSidePanel(shouldExpand: hasMovedEnoughLeftOfCenter)
            }
        default:
            break
        }
        
    }
    
    private func applyTranslationToViews(recognizer:UIPanGestureRecognizer) {
        recognizer.view!.center.x = recognizer.view!.center.x + recognizer.translationInView(view).x
        nowPlayingNavigationController!.view.center.x = nowPlayingNavigationController!.view!.center.x + recognizer.translationInView(view).x
        var fraction = (recognizer.view!.center.x - view.center.x)/(centerPanelExpandedXPosition)
        let transform = transformForFraction(fraction)
        nowPlayingNavigationController?.view.layer.transform = transform
        recognizer.setTranslation(CGPointZero, inView: view)
    }
    
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let gestureIsDraggingFromLeftToRight = (recognizer.velocityInView(view).x > 0)
        
        switch(recognizer.state) {
        case .Changed:
            applyTranslationToViews(recognizer)
        case .Ended, .Cancelled:
            if(nowPlayingViewController != nil) {
                let hasMovedEnoughRightOfScreenEdge = recognizer.view!.center.x < -(self.view.center.x * 0.90)
                animateSidePanel(shouldExpand: hasMovedEnoughRightOfScreenEdge)
            }
        default:
            break
        }
        
    }
    
    func handleLongPressGesture(recognizer:UILongPressGestureRecognizer) {
        if (recognizer.state == UIGestureRecognizerState.Began) {
            //initialize the drag and drop handler and all the resources necessary for the drag and drop handler
            addSidePanelViewController()
            if(!nowPlayingViewController!.laidOutSubviews) {
                dispatch_async(dispatch_get_main_queue()) { self.handleLongPressGesture(recognizer) }
                return
            }
            if(dragAndDropHandler == nil) {
                dragAndDropHandler = LongPressDragAndDropGestureHandler(dragSource: rootViewController, dropDestination: nowPlayingViewController!)
                dragAndDropHandler.delegate = self
            }
        }
        dragAndDropHandler.handleGesture(recognizer)
    }

    
    //MARK: INSERT MODE DELEGATION METHODS

    func gestureDidBegin(sender: UIGestureRecognizer) {
        if(sender == longPressGestureRecognizer) {
            animateSidePanel(shouldExpand: true)
            nowPlayingViewController!.insertMode = true
        }
    }
    
    func gestureDidEnd(sender: UIGestureRecognizer) {
        nowPlayingViewController!.insertMode = false
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeDelayInNanoSeconds), dispatch_get_main_queue()) { [unowned self]() in
            self.animateSidePanel(shouldExpand: false)
            self.dragAndDropHandler = nil
        }
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(gestureRecognizer.isEqual(longPressGestureRecognizer)) {
            return (!rootViewController.pullableViewExpanded && !sidePanelExpanded)
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
