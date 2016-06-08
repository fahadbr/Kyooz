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
    
    enum Position : Int { case Left, Center, Right }
    
    private let sideVCOffset:CGFloat = 60
	private var invertedCenterVCOffset:CGFloat { return view.bounds.width - sideVCOffset }
	private var kvoContext:UInt8 = 123
    
    var longPressGestureRecognizer:UILongPressGestureRecognizer!
    var dragAndDropHandler:LongPressDragAndDropGestureHandler!
    
    var tapGestureRecognizer:UITapGestureRecognizer!
    var centerPanelPanGestureRecognizer:UIPanGestureRecognizer!
    
    lazy var rootViewController:RootViewController = RootViewController.instance
    
    private var nowPlayingNavigationController:UINavigationController!
    private let nowPlayingQueueViewController = NowPlayingQueueViewController.instance
    private let searchViewController = AudioEntitySearchViewController.instance
    private let kyoozNavigationViewController = KyoozNavigationViewController()
    
    var centerPanelPosition:Position = .Center {
        didSet {
            searchViewController.isExpanded = centerPanelPosition == .Right
            let sidePanelVisible = centerPanelPosition != .Center
            tapGestureRecognizer.enabled = sidePanelVisible
            rootViewController.enableGesturesInSubViews(shouldEnable: !sidePanelVisible)
            nowPlayingQueueViewController.isExpanded = centerPanelPosition == .Left
			showTutorials()
        }
    }
    
    private let _undoManager:NSUndoManager = {
        let undoManager = NSUndoManager()
        undoManager.levelsOfUndo = 2
        return undoManager
    }()
    
    override var undoManager:NSUndoManager! {
        return _undoManager
    }
    
    private var centerViewRightConstraint:NSLayoutConstraint!
    
    deinit {
        unregisterForNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForNotifications()
        
        let rootView = rootViewController.view
        addChildViewController(rootViewController)
        rootViewController.didMoveToParentViewController(self)
        rootView.layer.shadowOffset = CGSize(width: 0, height: 0)
        rootView.layer.shadowRadius = 6
        rootView.addObserver(self, forKeyPath: "center", options: NSKeyValueObservingOptions.New, context: &kvoContext)
		
		centerViewRightConstraint = ConstraintUtils.applyConstraintsToView(
			withAnchors: [.Top, .Bottom, .Width, .Right],
			subView: rootView,
			parentView: view)[.Right]!
		
        centerPanelPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ContainerViewController.handlePanGesture(_:)))
        centerPanelPanGestureRecognizer.delegate = self
        rootViewController.view.addGestureRecognizer(centerPanelPanGestureRecognizer)
        if let popGR = rootViewController.libraryNavigationController.interactivePopGestureRecognizer {
            ContainerViewController.instance.centerPanelPanGestureRecognizer.requireGestureRecognizerToFail(popGR)
        }

        //keep a reference of this gesture recogizer to enable/disable it
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ContainerViewController.handleTouchGesture(_:)))
        tapGestureRecognizer.enabled = false
        rootViewController.view.addGestureRecognizer(tapGestureRecognizer)

        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ContainerViewController.handleLongPressGesture(_:)))
        longPressGestureRecognizer.delegate = self
        view.addGestureRecognizer(longPressGestureRecognizer)
		
		//NOW PLAYING VC
        
		
		nowPlayingNavigationController = UINavigationController(rootViewController: nowPlayingQueueViewController)
		
		nowPlayingNavigationController!.toolbarHidden = false
		let npView = nowPlayingNavigationController!.view
		addChildViewController(nowPlayingNavigationController!)
		nowPlayingNavigationController.didMoveToParentViewController(self)
		ConstraintUtils.applyConstraintsToView(withAnchors: [.Top, .Bottom, .Right, .Width], subView: npView, parentView: view)[.Width]!.constant = -sideVCOffset
		view.sendSubviewToBack(npView)
        nowPlayingNavigationController.navigationBar.backgroundColor = UIColor.clearColor()
        nowPlayingNavigationController.navigationBar.setBackgroundImage(UIImage(), forBarPosition: .Any, barMetrics: .Default)
        nowPlayingNavigationController.navigationBar.shadowImage = UIImage()
		
		nowPlayingQueueViewController.view.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Top, .Bottom, .Left, .Width], subView: searchViewController.view, parentView: view)[.Width]!.constant = -sideVCOffset
        addChildViewController(searchViewController)
        view.sendSubviewToBack(searchViewController.view)
        searchViewController.didMoveToParentViewController(self)
    }
	
    func dismissTutorials(targetPosition:Position) {
        switch targetPosition {
        case .Right:
            if !TutorialManager.instance.dismissTutorial(.GestureActivatedSearch, action: .Fulfill) {
                TutorialManager.instance.dimissTutorials([.GestureToViewQueue], action: .DismissUnfulfilled)
            }
        case .Left:
            if !TutorialManager.instance.dismissTutorial(.GestureToViewQueue, action: .Fulfill) {
                TutorialManager.instance.dimissTutorials([.GestureActivatedSearch, .DragAndDrop], action: .DismissUnfulfilled)
            }
		case .Center:
			break
        }
	}
	
	func showTutorials() {
		if centerPanelPosition == .Center && !rootViewController.pullableViewExpanded {
			TutorialManager.instance.presentUnfulfilledTutorials([.GestureActivatedSearch, .GestureToViewQueue, .DragAndDrop])
		}
	}
	
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
	
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        KyoozUtils.doInMainQueueAfterDelay(3) {
            self.showTutorials()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    func toggleSidePanel() {
        let newPosition:Position = centerPanelPosition == .Center ? .Left : .Center
        animateCenterPanel(toPosition: newPosition)
    }
    
    override func childViewControllerForStatusBarHidden() -> UIViewController? {
        return rootViewController
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func pushViewController(vc:UIViewController) {
        if centerPanelPosition != .Center {
            animateCenterPanel(toPosition: .Center)
        }
        rootViewController.pushViewController(vc)
    }
    
    func pushNewMediaEntityControllerWithProperties(sourceData:AudioEntitySourceData, parentGroup:LibraryGrouping, entity:AudioEntity) {
        
        if let item = entity as? MPMediaItem {
            guard IPodLibraryDAO.queryMediaItemFromId(NSNumber(unsignedLongLong: item.persistentID)) != nil else {
                var name = parentGroup.name.capitalizedString
                name.removeAtIndex(name.endIndex.predecessor())
                KyoozUtils.showPopupError(withTitle: "Track Not Found In Library",
                    withMessage: "Kyooz can't show details about this track's \(name) because it's not in your music library.",
                    presentationVC: self)
                return
            }
        }
		
		guard !sourceData.entities.isEmpty else {
			KyoozUtils.showPopupError(withTitle: "No music was found in the selected item",
			                          withMessage: nil,
			                          presentationVC: self)
			return
		}
        
		let vc = AudioEntityLibraryViewController()
        vc.sourceData = sourceData
        
        if parentGroup.usesArtwork {
			vc.useCollapsableHeader = true
        } else {
            vc.title = entity.titleForGrouping(parentGroup)?.uppercaseString
        }
		
        pushViewController(vc)
    }
    
    func presentKyoozNavigationController() {
        let nc = kyoozNavigationViewController
        ConstraintUtils.applyStandardConstraintsToView(subView: nc.view, parentView: view)
        addChildViewController(nc)
        nc.didMoveToParentViewController(self)
        longPressGestureRecognizer.enabled = false
    }
    
    //MARK: NOTIFICATION REGISTRATIONS
    
    private func registerForNotifications() {
        
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    // MARK: Gesture recognizer
    
    func handleTouchGesture(recognizer:UITapGestureRecognizer) {
        if recognizer.state == .Ended {
            toggleSidePanel()
        }
    }
    
    private func animateCenterPanel(toPosition targetPosition:Position) {
        if centerPanelPosition == .Left && targetPosition == .Center {
            animateCenterPanelXPosition(toPosition: targetPosition) { finished in
                self.centerPanelPosition = targetPosition
            }
        } else {
            centerPanelPosition = targetPosition
            animateCenterPanelXPosition(toPosition: targetPosition)
        }
    }
	
    
    private func animateCenterPanelXPosition(toPosition targetPosition:Position, completion: ((Bool) -> Void)! = nil) {
        switch targetPosition {
        case .Center:
            centerViewRightConstraint.constant = 0
        case .Left:
            centerViewRightConstraint.constant = -invertedCenterVCOffset
        case .Right:
            centerViewRightConstraint.constant = invertedCenterVCOffset
        }
        
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
		let newConstant = centerViewRightConstraint.constant + recognizer.translationInView(view).x
		centerViewRightConstraint.constant = KyoozUtils.cap(newConstant, min: -invertedCenterVCOffset, max: invertedCenterVCOffset)
        recognizer.setTranslation(CGPoint.zero, inView: view)
    }
    
    
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {

        switch(recognizer.state) {
        case .Changed:
            applyTranslationToViews(recognizer)
        case .Ended, .Cancelled:
            let targetPosition:Position
            let centerPanelXPos = rootViewController.view.frame.origin.x
            
            let movingRight = recognizer.velocityInView(recognizer.view).x > 0
            
            
            if centerPanelXPos < 0 {
                let markerX = movingRight ? (invertedCenterVCOffset * -0.80) : (invertedCenterVCOffset * -0.20)
                targetPosition = centerPanelXPos < markerX ? .Left : .Center
            } else if centerPanelXPos > 0 {
                let markerX = movingRight ? (invertedCenterVCOffset * 0.20) : (invertedCenterVCOffset * 0.80)
                targetPosition = centerPanelXPos > markerX ? .Right : .Center
            } else {
                targetPosition = .Center
            }
            dismissTutorials(targetPosition)
            animateCenterPanel(toPosition: targetPosition)
        default:
            break
        }
        
    }
    
    func handleLongPressGesture(recognizer:UILongPressGestureRecognizer) {
        switch(recognizer.state) {
        case .Began:
            //initialize the drag and drop handler and all the resources necessary for the drag and drop handler
            if(!nowPlayingQueueViewController.laidOutSubviews) {
                dispatch_async(dispatch_get_main_queue()) { self.handleLongPressGesture(recognizer) }
                return
            }
            if(dragAndDropHandler == nil) {
                let dragSource:DragSource = centerPanelPosition == .Right ? searchViewController : rootViewController
                dragAndDropHandler = LongPressDragAndDropGestureHandler(dragSource: dragSource, dropDestination: nowPlayingQueueViewController)
                dragAndDropHandler.delegate = self
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
			let fraction = Float(abs(centerViewRightConstraint.constant)/invertedCenterVCOffset)
			rootViewController.view.layer.shadowOpacity = fraction
            CATransaction.commit()
            
            if centerViewRightConstraint.constant > 0 {
                nowPlayingNavigationController!.view.hidden = true
                searchViewController.view.hidden = false
            } else if centerViewRightConstraint.constant < 0 {
                nowPlayingNavigationController!.view.hidden = false
                searchViewController.view.hidden = true
            }
		}
	}

    
    //MARK: INSERT MODE DELEGATION METHODS

    func gestureDidBegin(sender: UIGestureRecognizer) {
        if(sender == longPressGestureRecognizer) {
			TutorialManager.instance.dismissTutorial(.DragAndDrop, action: .Fulfill)
            nowPlayingQueueViewController.insertMode = true
            animateCenterPanel(toPosition: .Left)
        }
    }
    
    func gestureDidEnd(sender: UIGestureRecognizer) {
        TutorialManager.instance.dismissTutorial(Tutorial.InsertOrCancel, action: .Fulfill)
        nowPlayingQueueViewController.insertMode = false
        KyoozUtils.doInMainQueueAfterDelay(0.3) { [unowned self]() in
            self.animateCenterPanel(toPosition: .Center)
            self.dragAndDropHandler = nil
        }
    }
    
    //MARK: - Gesture recognizer delegates
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === longPressGestureRecognizer {
            return (!rootViewController.pullableViewExpanded || centerPanelPosition == .Right)
        } else if gestureRecognizer === centerPanelPanGestureRecognizer {
            let translation = centerPanelPanGestureRecognizer.translationInView(centerPanelPanGestureRecognizer.view)
            return abs(translation.x) > abs(translation.y)
        }
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
   
}
