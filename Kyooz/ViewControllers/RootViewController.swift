//
//  RootViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/15/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class RootViewController: UIViewController, DragSource, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    static let instance:RootViewController = RootViewController()
    
    static let nowPlayingViewCollapsedOffset:CGFloat = NowPlayingSummaryViewController.CollapsedHeight

    var pullableViewExpanded:Bool  {
        get {
            return nowPlayingSummaryViewController.expanded
        } set {
            nowPlayingSummaryViewController.expanded = newValue
            nowPlayingTapGestureRecognizer.enabled = !newValue
            TutorialManager.instance.dimissTutorials([.DragAndDrop], action: .DismissUnfulfilled)
        }
    }
    
    var sourceTableView:UITableView? {
        return (libraryNavigationController.topViewController as? AudioEntityViewControllerProtocol)?.tableView
    }
    
    var libraryNavigationController:UINavigationController!
    private var lncBottomConstraint:NSLayoutConstraint!
    
    var nowPlayingSummaryViewController:NowPlayingSummaryViewController!
    
    var nowPlayingTapGestureRecognizer:UITapGestureRecognizer!
    var nowPlayingPanGestureRecognizer:UIPanGestureRecognizer!
    private var collapsedConstraint:NSLayoutConstraint!
    private var expandedConstraint:NSLayoutConstraint!
    
    private var collapsedBarLayoutGuide:UILayoutGuide!
    
    private var warningViewController:WarningViewController?
    private lazy var reducedAnimationDelegate = ReducedAnimationNavigationControllerDelegate()
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let aelvc = AudioEntityLibraryViewController()
        let baseGroupIndex = NSUserDefaults.standardUserDefaults().integerForKey(UserDefaultKeys.AllMusicBaseGroup)
        let selectedGroup = LibraryGrouping.allMusicGroupings[baseGroupIndex]
        aelvc.title = "ALL MUSIC"
        aelvc.sourceData = MediaQuerySourceData(filterQuery: selectedGroup.baseQuery, libraryGrouping: selectedGroup)
		
		libraryNavigationController = UINavigationController(rootViewController: aelvc)
		
        collapsedBarLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(collapsedBarLayoutGuide)
        collapsedBarLayoutGuide.heightAnchor.constraintEqualToConstant(self.dynamicType.nowPlayingViewCollapsedOffset).active = true
        collapsedBarLayoutGuide.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        collapsedBarLayoutGuide.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        collapsedBarLayoutGuide.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        
        view.addSubview(libraryNavigationController.view)
        addChildViewController(libraryNavigationController)
        libraryNavigationController.didMoveToParentViewController(self)
        libraryNavigationController.navigationBar.backgroundColor = UIColor.clearColor()
        libraryNavigationController.navigationBar.setBackgroundImage(UIImage(), forBarPosition: .Any, barMetrics: .Default)
        libraryNavigationController.navigationBar.shadowImage = UIImage()

        setNavigationDelegate()
        
        let libraryView = libraryNavigationController.view
        libraryView.translatesAutoresizingMaskIntoConstraints = false
        libraryView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        lncBottomConstraint = libraryView.bottomAnchor.constraintEqualToAnchor(collapsedBarLayoutGuide.topAnchor)
        lncBottomConstraint.active = true
        libraryView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        libraryView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        
        nowPlayingSummaryViewController = NowPlayingSummaryViewController()
        
        let nowPlayingView = nowPlayingSummaryViewController.view
        view.insertSubview(nowPlayingView, atIndex: 0)
        view.bringSubviewToFront(nowPlayingView)
        addChildViewController(nowPlayingSummaryViewController)
        nowPlayingSummaryViewController.didMoveToParentViewController(self)
        nowPlayingView.translatesAutoresizingMaskIntoConstraints = false
        collapsedConstraint = nowPlayingView.topAnchor.constraintEqualToAnchor(collapsedBarLayoutGuide.topAnchor)
        collapsedConstraint.active = true
        expandedConstraint = nowPlayingView.topAnchor.constraintEqualToAnchor(view.topAnchor)
        
        nowPlayingView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        nowPlayingView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        nowPlayingView.heightAnchor.constraintEqualToAnchor(view.heightAnchor).active = true

        nowPlayingPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(RootViewController.handlePanGesture(_:)))
        nowPlayingPanGestureRecognizer.delegate = self
        nowPlayingSummaryViewController.view.addGestureRecognizer(self.nowPlayingPanGestureRecognizer)
        
        nowPlayingTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(RootViewController.handleTapGesture(_:)))
        nowPlayingTapGestureRecognizer.delegate = self
        nowPlayingSummaryViewController.view.addGestureRecognizer(self.nowPlayingTapGestureRecognizer)
    }
    
    
    override func viewDidAppear(animated: Bool) {
        //explicitly setting this here
        pullableViewExpanded = false
    }
    
    //MARK: - Navigation controller delegate
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        if !navigationController.toolbarHidden {
            navigationController.toolbarHidden = true
        }
    }
    
    func setNavigationDelegate() {
        let reduceAnimations = NSUserDefaults.standardUserDefaults().boolForKey(UserDefaultKeys.ReduceAnimations)
        if reduceAnimations {
            libraryNavigationController.delegate = reducedAnimationDelegate
        } else {
            libraryNavigationController.delegate = self
        }
        (libraryNavigationController.topViewController as? CustomPopableViewController)?.enableCustomPopGestureRecognizer(reduceAnimations)
    }
    
    func presentWarningView(message:String, handler:()->()) {
        if self.warningViewController != nil {
            Logger.debug("already displaying warning view")
            return
        }
        let warningVC = UIStoryboard.warningViewController()
        warningVC.handler = handler
        warningVC.message = message
        
        let warningView = warningVC.view
        warningView.frame = CGRect(origin: collapsedBarLayoutGuide.layoutFrame.origin, size: CGSize(width: view.frame.width, height: 0))
        view.insertSubview(warningView, belowSubview: nowPlayingSummaryViewController.view)
        warningViewController = warningVC
        
        warningView.translatesAutoresizingMaskIntoConstraints = false
        lncBottomConstraint.active = false
        warningView.topAnchor.constraintEqualToAnchor(libraryNavigationController.view.bottomAnchor).active = true
        warningView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        warningView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        warningView.heightAnchor.constraintEqualToConstant(40).active = true
        warningView.bottomAnchor.constraintEqualToAnchor(collapsedBarLayoutGuide.topAnchor).active = true
        warningVC.warningButton.alpha = 0
        UIView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .CurveEaseInOut, animations: { () -> Void in
            self.view.layoutIfNeeded()
            warningVC.warningButton.alpha = 1
            }, completion: nil)

    }
    
    func dismissWarningView() {
        guard let warningVC = self.warningViewController else {
            return
        }
        
        guard let heightConstraint = warningVC.view.constraints.filter({
            return $0.firstAttribute == NSLayoutAttribute.Height && $0.firstItem === warningVC.view && $0.secondItem == nil
        }).first else { return }
        heightConstraint.constant = 0
        warningVC.warningButton.hidden = true
        UIView.animateWithDuration(0.15, delay: 0, options: .CurveEaseInOut, animations: { self.view.layoutIfNeeded() }, completion: {_ in
            warningVC.view.removeFromSuperview()
            self.lncBottomConstraint.active = true
            self.warningViewController = nil
        })
    }
    
    func setToolbarHidden(hidden:Bool) {
        libraryNavigationController.setToolbarHidden(hidden, animated: true)
    }
    
    func pushViewController(vc:UIViewController) {
        if(pullableViewExpanded) {
            animatePullablePanel(shouldExpand: false)
        }
        libraryNavigationController.pushViewController(vc, animated: true)
    }
    
    func enableGesturesInSubViews(shouldEnable shouldEnable:Bool) {
        libraryNavigationController.view.userInteractionEnabled = shouldEnable
        nowPlayingSummaryViewController.view.userInteractionEnabled = shouldEnable
        sourceTableView?.scrollsToTop = shouldEnable
    }
    
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let isDraggingUpward = (recognizer.velocityInView(view).y < 0)
        let currenyYPos = recognizer.view!.frame.origin.y
        
        let activeConstraint = expandedConstraint.active ? expandedConstraint : collapsedConstraint
        
        switch(recognizer.state) {
        case .Changed:
            let translationY = recognizer.translationInView(self.view).y
            let endYPos = currenyYPos + translationY
            
            if(endYPos >= view.frame.minY && endYPos <= collapsedBarLayoutGuide.layoutFrame.minY) {
                activeConstraint.constant += translationY

                recognizer.setTranslation(CGPointZero, inView: view)
            }
        case .Ended, .Cancelled:
            if(nowPlayingSummaryViewController != nil) {
                if(isDraggingUpward) {
                    animatePullablePanel(shouldExpand: (currenyYPos < self.view.frame.height * 0.80))
                } else {
                    animatePullablePanel(shouldExpand: (currenyYPos < self.view.frame.height * 0.10))
                }
            }
        default:
            break
        }
        
    }
    
    func getSourceData() -> AudioEntitySourceData? {
        if let mediaItemViewController = libraryNavigationController.viewControllers.last as? AudioEntityViewControllerProtocol {
            return mediaItemViewController.getSourceData()
        }
        Logger.debug("Couldnt get a view controller with media items, returning nil")
        return nil
    }
    
    func handleTapGesture(recognizer: UITapGestureRecognizer) {
        if(!pullableViewExpanded) {
            animatePullablePanel(shouldExpand: true)
        }
    }
    
    func animatePullablePanel(shouldExpand shouldExpand:Bool) {
        if shouldExpand { //need to make sure one is deactivated before activating the other
            collapsedConstraint.active = false
            expandedConstraint.active = true
        } else {
            expandedConstraint.active = false
            collapsedConstraint.active = true
        }
        
        collapsedConstraint.constant = 0
        expandedConstraint.constant = 0
        
        var completionBlock:((Bool)->Void)?
        if(shouldExpand) {
            pullableViewExpanded = true
        } else {
            completionBlock = { finished in
                self.pullableViewExpanded = false
            }
        }
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: completionBlock)
    }
    
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === nowPlayingPanGestureRecognizer {
            let translation = nowPlayingPanGestureRecognizer.translationInView(nowPlayingPanGestureRecognizer.view)
            return abs(translation.y) > abs(translation.x)
        }
        return true
    }
	
	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return gestureRecognizer is UISwipeGestureRecognizer && otherGestureRecognizer === nowPlayingPanGestureRecognizer
	}
	
	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return false
	}
	
	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return gestureRecognizer === nowPlayingPanGestureRecognizer && otherGestureRecognizer is UISwipeGestureRecognizer
	}
}

private class ReducedAnimationNavigationControllerDelegate : NSObject, UINavigationControllerDelegate {
    
    private let transition = ViewControllerFadeAnimator.instance
    
    //MARK: - Navigation controller delegate
    @objc func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        if !navigationController.toolbarHidden {
            navigationController.toolbarHidden = true
        }
    }
    
    @objc func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.operation = operation
        return transition
    }
    
    @objc func navigationController(navigationController: UINavigationController, interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if transition.interactive {
            return transition
        }
        return nil
    }
}
