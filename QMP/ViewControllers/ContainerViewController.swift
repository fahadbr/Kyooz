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
    
    private let sideVCOffset:CGFloat = 60
	private var invertedSideVCOffset:CGFloat { return view.bounds.width - sideVCOffset }
	private var kvoContext:UInt8 = 123
    
    var longPressGestureRecognizer:UILongPressGestureRecognizer!
    var dragAndDropHandler:LongPressDragAndDropGestureHandler!
    
    var tapGestureRecognizer:UITapGestureRecognizer!
    var panGestureRecognizer:UIPanGestureRecognizer!
    var rightPanelExpandingGestureRecognizer:UIPanGestureRecognizer!
    
    var rootViewController:RootViewController!
    
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
    
    private let _undoManager:NSUndoManager = {
            let u = NSUndoManager()
            u.levelsOfUndo = 2
            return u
    }()
    
    override var undoManager:NSUndoManager! {
        return _undoManager
    }
    
    private var queueViewLeftConstraint:NSLayoutConstraint!
    
    deinit {
        unregisterForNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForNotifications()
        
        rootViewController = RootViewController.instance
        
        let rootView = rootViewController.view
        addChildViewController(rootViewController)
        rootViewController.didMoveToParentViewController(self)
        rootView.layer.shadowOffset = CGSize(width: 3, height: 0)
        rootView.addObserver(self, forKeyPath: "center", options: NSKeyValueObservingOptions.New, context: &kvoContext)
		
		queueViewLeftConstraint = ConstraintUtils.applyConstraintsToView(
			withAnchors: [.Top, .Bottom, .Width, .Right],
			subView: rootView,
			parentView: view)[.Right]!
		
        rightPanelExpandingGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ContainerViewController.handleScreenEdgePanGesture(_:)))
        rightPanelExpandingGestureRecognizer.delegate = self
        rootViewController.view.addGestureRecognizer(rightPanelExpandingGestureRecognizer)

        //keep a reference of this gesture recogizer to enable/disable it
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ContainerViewController.handleTouchGesture(_:)))
        tapGestureRecognizer.enabled = sidePanelExpanded
        rootViewController.view.addGestureRecognizer(tapGestureRecognizer)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ContainerViewController.handlePanGesture(_:)))
        panGestureRecognizer.enabled = sidePanelExpanded
        rootViewController.view.addGestureRecognizer(panGestureRecognizer)
        

        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ContainerViewController.handleLongPressGesture(_:)))
        longPressGestureRecognizer.delegate = self
        view.addGestureRecognizer(longPressGestureRecognizer)
		
		//NOW PLAYING VC
        
		nowPlayingViewController = UIStoryboard.nowPlayingViewController()
		nowPlayingViewController?.tableView?.scrollsToTop = false
		
		nowPlayingNavigationController = UINavigationController(rootViewController: nowPlayingViewController!)
		
		nowPlayingNavigationController!.toolbarHidden = false
		let npView = nowPlayingNavigationController!.view
		addChildViewController(nowPlayingNavigationController!)
		nowPlayingNavigationController!.didMoveToParentViewController(self)
		ConstraintUtils.applyConstraintsToView(withAnchors: [.Top, .Bottom, .Right, .Width], subView: npView, parentView: view)[.Width]!.constant = -sideVCOffset
		view.sendSubviewToBack(npView)
		
		nowPlayingViewController!.view.layer.rasterizationScale = UIScreen.mainScreen().scale
		
        

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
        animateSidePanel(shouldExpand: !sidePanelExpanded)
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
        
		let vc = AudioEntityLibraryViewController()
        vc.subGroups = parentGroup.subGroupsForNextLevel
        vc.sourceData = sourceData
        
        if parentGroup === LibraryGrouping.Albums || parentGroup === LibraryGrouping.Compilations {
			vc.useCollapsableHeader = true
        }
		
		vc.title = entity.titleForGrouping(parentGroup)?.uppercaseString
		
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
            nowPlayingViewController?.view.layer.shouldRasterize = true
        case .Changed:
            applyTranslationToViews(recognizer)
        case .Ended, .Cancelled:
            if(nowPlayingViewController != nil) {
                let hasMovedEnoughLeftOfCenter = (queueViewLeftConstraint.constant/(-invertedSideVCOffset)) > 0.15
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
                sideVCOffset, shouldExpand: shouldExpand) { finished in

                    self.nowPlayingViewController?.view?.layer.shouldRasterize = false
            }
            
        } else {
            animateCenterPanelXPosition(targetPosition: 0, shouldExpand: shouldExpand) { finished in
                self.sidePanelExpanded = false
                self.nowPlayingViewController?.view?.layer.shouldRasterize = false
            }
        }
    }
	
    
    private func animateCenterPanelXPosition(targetPosition targetPosition:CGFloat, shouldExpand:Bool, completion: ((Bool) -> Void)! = nil) {
		queueViewLeftConstraint.constant = shouldExpand ? -invertedSideVCOffset : 0
        
        UIView.animateWithDuration(0.4,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0,
            options: .CurveEaseInOut,
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: completion)
    }

    
    private func applyTranslationToViews(recognizer:UIPanGestureRecognizer) {
	
		
		let newConstant = queueViewLeftConstraint.constant + recognizer.translationInView(view).x
		queueViewLeftConstraint.constant = KyoozUtils.cap(newConstant, min: -invertedSideVCOffset, max: 0)
		
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
            if(!nowPlayingViewController!.laidOutSubviews) {
                dispatch_async(dispatch_get_main_queue()) { self.handleLongPressGesture(recognizer) }
                return
            }
            if(dragAndDropHandler == nil) {
                dragAndDropHandler = LongPressDragAndDropGestureHandler(dragSource: rootViewController, dropDestination: nowPlayingViewController!)
                dragAndDropHandler.delegate = self
            }
        case .Ended, .Cancelled:
            nowPlayingViewController!.insertMode = false
            dispatch_after(KyoozUtils.getDispatchTimeForSeconds(0.6), dispatch_get_main_queue()) { [unowned self]() in
                self.animateSidePanel(shouldExpand: false)
                self.dragAndDropHandler = nil
            }
        default:
            break
        }
        dragAndDropHandler?.handleGesture(recognizer)
    }
	
	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		if keyPath != nil && keyPath! == "center" {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
			let fraction = Float(queueViewLeftConstraint.constant/(-invertedSideVCOffset))
			rootViewController?.view.layer.shadowOpacity = fraction * 0.8
            CATransaction.commit()
		}
	}

    
    //MARK: INSERT MODE DELEGATION METHODS

    func gestureDidBegin(sender: UIGestureRecognizer) {
        if(sender == longPressGestureRecognizer) {
            animateSidePanel(shouldExpand: true)
            nowPlayingViewController!.insertMode = true
        }
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === longPressGestureRecognizer {
            return (!rootViewController.pullableViewExpanded && !sidePanelExpanded)
        } else if gestureRecognizer === rightPanelExpandingGestureRecognizer {
            let translation = rightPanelExpandingGestureRecognizer.translationInView(rightPanelExpandingGestureRecognizer.view)
            return abs(translation.x) > abs(translation.y)
        }
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer === rightPanelExpandingGestureRecognizer {
            return gestureRecognizer.view is UITableView 
        }
        return otherGestureRecognizer is UIScreenEdgePanGestureRecognizer || otherGestureRecognizer is UISwipeGestureRecognizer
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === rightPanelExpandingGestureRecognizer {
            return otherGestureRecognizer.view is UITableView
        }
        return gestureRecognizer is UIScreenEdgePanGestureRecognizer || gestureRecognizer is UISwipeGestureRecognizer
    }
   
}
