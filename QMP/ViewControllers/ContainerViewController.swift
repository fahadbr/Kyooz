//
//  ContainerViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/15/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class ContainerViewController : UIViewController , GestureHandlerDelegate, UIGestureRecognizerDelegate {
    
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
            for gestureRecognizerObject in rootViewController.view.gestureRecognizers! {
                let gestureRecognizer = gestureRecognizerObject 
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
    
    private var _undoManager:NSUndoManager = {
            let u = NSUndoManager()
            u.levelsOfUndo = 2
            return u
    }()
    
    override var undoManager:NSUndoManager! {
        return _undoManager
    }
    
    private var collapsedConstraint:NSLayoutConstraint!
    private var expandedConstraint:NSLayoutConstraint!
    
    deinit {
        unregisterForNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForNotifications()
        
        rootViewController = RootViewController.instance
        
        let rootView = rootViewController.view
        view.addSubview(rootView)
        addChildViewController(rootViewController)
        rootViewController.didMoveToParentViewController(self)
        
        rootView.translatesAutoresizingMaskIntoConstraints = false
        rootView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        rootView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        rootView.widthAnchor.constraintEqualToAnchor(view.widthAnchor).active = true
        collapsedConstraint = rootView.rightAnchor.constraintEqualToAnchor(view.rightAnchor)
        collapsedConstraint.active = true
        expandedConstraint = rootView.rightAnchor.constraintEqualToAnchor(view.leftAnchor, constant: centerPanelExpandedOffset)
        
        screenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "handleScreenEdgePanGesture:")
        screenEdgePanGestureRecognizer.edges = UIRectEdge.Right
        screenEdgePanGestureRecognizer.delegate = self
        rootViewController.view.addGestureRecognizer(screenEdgePanGestureRecognizer)

        //keep a reference of this gesture recogizer to enable/disable it
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTouchGesture:")
        tapGestureRecognizer.enabled = sidePanelExpanded
        rootViewController.view.addGestureRecognizer(tapGestureRecognizer)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        panGestureRecognizer.enabled = sidePanelExpanded
        rootViewController.view.addGestureRecognizer(panGestureRecognizer)
        

        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPressGesture:")
        longPressGestureRecognizer.delegate = self
        view.addGestureRecognizer(longPressGestureRecognizer)
        
        addSidePanelViewController()
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    func toggleSidePanel() {
        if(!sidePanelExpanded) {
            addSidePanelViewController()
        }
        animateSidePanel(shouldExpand: !sidePanelExpanded)
    }
    
    func addSidePanelViewController() {
        if(nowPlayingViewController == nil) {
            nowPlayingViewController = UIStoryboard.nowPlayingViewController()
            nowPlayingViewController?.tableView?.scrollsToTop = false
            
            nowPlayingNavigationController = UINavigationController(rootViewController: nowPlayingViewController!)

            nowPlayingNavigationController!.toolbarHidden = false
            let npView = nowPlayingNavigationController!.view
            npView.layer.anchorPoint = CGPoint(x: 0.0, y: 0.5)
            view.insertSubview(npView, atIndex: 0)
            addChildViewController(nowPlayingNavigationController!)
            nowPlayingNavigationController!.didMoveToParentViewController(self)
            npView.translatesAutoresizingMaskIntoConstraints = false
            npView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
            npView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
            npView.centerXAnchor.constraintEqualToAnchor(rootViewController.view.rightAnchor).active = true
            npView.widthAnchor.constraintEqualToAnchor(view.widthAnchor, constant: -centerPanelExpandedOffset).active = true

            nowPlayingViewController!.view.layer.rasterizationScale = UIScreen.mainScreen().scale
        }
    }
    
    
    
    func pushViewController(vc:UIViewController) {
        if sidePanelExpanded {
            animateSidePanel(shouldExpand: false)
        }
        rootViewController.pushViewController(vc)
    }
    
    func pushNewMediaEntityControllerWithProperties(sourceData:AudioEntitySourceData, parentGroup:LibraryGrouping, entity:AudioEntity) {
        
        if let item = entity as? MPMediaItem {
            if IPodLibraryDAO.queryMediaItemFromId(NSNumber(unsignedLongLong: item.persistentID)) == nil {
                var name = parentGroup.name.capitalizedString
                name.removeAtIndex(name.endIndex.predecessor())
                KyoozUtils.showPopupError(withTitle: "Track Not Found In Library",
                    withMessage: "Kyooz can't show details about this track's \(name) because it's not in your music library.",
                    presentationVC: self)
                return
            }
        }
        
        let vc = UIStoryboard.audioEntityHeaderViewController()
        vc.subGroups = parentGroup.subGroupsForNextLevel
        vc.sourceData = sourceData
        
        if parentGroup === LibraryGrouping.Albums || parentGroup === LibraryGrouping.Compilations {
			vc.useCollectionDetailsHeader = true
        } else {
            vc.title = entity.titleForGrouping(parentGroup)?.uppercaseString
        }
		
        pushViewController(vc)
    }
    
    //MARK: NOTIFICATION REGISTRATIONS
    
    private func registerForNotifications() {
        
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    // MARK: Gesture recognizer
    
    func handleTouchGesture(recognizer:UITapGestureRecognizer) {
        if(recognizer.state == .Ended) {
            toggleSidePanel()
        }
    }
    
    func handleScreenEdgePanGesture(recognizer: UIPanGestureRecognizer) {

        switch(recognizer.state) {
        case .Began:
            let gestureIsDraggingFromLeftToRight = (recognizer.velocityInView(view).x > 0)
            if(!sidePanelExpanded && !gestureIsDraggingFromLeftToRight) {
                addSidePanelViewController()
            }
            nowPlayingViewController?.view.layer.shouldRasterize = true
        case .Changed:
            applyTranslationToViews(recognizer)
        case .Ended, .Cancelled:
            if(nowPlayingViewController != nil) {
                let hasMovedEnoughLeftOfCenter = recognizer.view!.center.x < (view.center.x * 0.90)
                animateSidePanel(shouldExpand: hasMovedEnoughLeftOfCenter)
            }
        default:
            break
        }
        
    }
    
    private func animateSidePanel(shouldExpand shouldExpand: Bool) {
        if shouldExpand {
            self.sidePanelExpanded = true
            animateCenterPanelXPosition(targetPosition: -CGRectGetWidth(rootViewController.view.frame) +
                centerPanelExpandedOffset, shouldExpand: shouldExpand) { finished in

                    self.nowPlayingViewController?.view?.layer.shouldRasterize = false
            }
            
        } else {
            animateCenterPanelXPosition(targetPosition: 0, shouldExpand: shouldExpand) { finished in
                self.sidePanelExpanded = false
                self.nowPlayingViewController?.view?.layer.shouldRasterize = false
            }
        }
    }
    
    private func transformForFraction(var fraction:CGFloat) -> CATransform3D{
        //make sure that the fraction does not go past the 1 or 0 bounds
        if fraction < 0 {
            fraction = 0
        } else if fraction > 1 {
            fraction = 1
        }
        
        var identity = CATransform3DIdentity
        identity.m34 = -1.0/1000
        let angle = Double(1.0 - fraction) * M_PI_2
        
        let rotateTransform = CATransform3DRotate(identity, CGFloat(angle), 0.0, 1.0, 0.0)
        return rotateTransform
    }
    
    private func animateCenterPanelXPosition(targetPosition targetPosition:CGFloat, shouldExpand:Bool, completion: ((Bool) -> Void)! = nil) {
        if shouldExpand { //need to make sure one is deactivated before activating the other
            collapsedConstraint.active = false
            expandedConstraint.active = true
        } else {
            expandedConstraint.active = false
            collapsedConstraint.active = true
        }
        
        expandedConstraint.constant = centerPanelExpandedOffset
        collapsedConstraint.constant = 0
        
        UIView.animateWithDuration(0.4,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0,
            options: .CurveEaseInOut,
            animations: {
                self.view.layoutIfNeeded()
                let fraction:CGFloat = (targetPosition - self.view.frame.origin.x)/self.centerPanelExpandedXPosition
                self.nowPlayingNavigationController?.view.layer.transform = self.transformForFraction(fraction)
                self.nowPlayingNavigationController?.view.alpha = fraction
            },
            completion: completion)
        
        
    }

    
    private func applyTranslationToViews(recognizer:UIPanGestureRecognizer) {
        var newOriginX = recognizer.view!.frame.origin.x + recognizer.translationInView(view).x
        
        if newOriginX < centerPanelExpandedXPosition {
            newOriginX = centerPanelExpandedXPosition
        } else if newOriginX > 0 {
            newOriginX = 0
        }
        
        let activeConstraint = expandedConstraint.active ? expandedConstraint : collapsedConstraint
        
        //the fraction is the percentage the center view controller has moved with respect to its final position (centerPanelExpandedXPosition)
        let fraction = (recognizer.view!.center.x - view.center.x)/(centerPanelExpandedXPosition)
        let transform = transformForFraction(fraction)
        nowPlayingNavigationController?.view.layer.transform = transform
        nowPlayingNavigationController?.view.alpha = fraction
        
        if 0 <= fraction && fraction <= 1 {
            activeConstraint.constant += recognizer.translationInView(view).x
        }
        
        recognizer.setTranslation(CGPointZero, inView: view)
    }
    
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        
        switch(recognizer.state) {
        case .Began:
            nowPlayingViewController!.view.layer.shouldRasterize = true
        case .Changed:
            applyTranslationToViews(recognizer)
        case .Ended, .Cancelled:
            if(nowPlayingViewController != nil) {
                let hasMovedEnoughRightOfScreenEdge = recognizer.view!.center.x < -(view.center.x * 0.90)
                animateSidePanel(shouldExpand: hasMovedEnoughRightOfScreenEdge)
            }
        default:
            break
        }
        
    }
    
    func handleLongPressGesture(recognizer:UILongPressGestureRecognizer) {
        switch(recognizer.state) {
        case .Began:
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
        default:
            break
        }
        dragAndDropHandler?.handleGesture(recognizer)
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
        if gestureRecognizer === longPressGestureRecognizer {
            return (!rootViewController.pullableViewExpanded && !sidePanelExpanded)
        }
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === screenEdgePanGestureRecognizer {
            return true
        }
        return false
    }
   
}
