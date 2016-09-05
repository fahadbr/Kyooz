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
    
	static var miniPlayerHeight:CGFloat {
		return NowPlayingViewController.miniPlayerHeight
	}

    var pullableViewExpanded:Bool  {
        get {
            return nowPlayingViewController.expanded
        } set {
            nowPlayingViewController.expanded = newValue
            nowPlayingTapGestureRecognizer.isEnabled = !newValue
            if newValue {
                TutorialManager.instance.dimissTutorials([.dragAndDrop], action: .dismissUnfulfilled)
            }
        }
    }
    
    var sourceTableView:UITableView? {
        return (libraryNavigationController.topViewController as? AudioEntityViewControllerProtocol)?.tableView
    }
    
    var libraryNavigationController:UINavigationController!
    private var lncBottomConstraint:NSLayoutConstraint!
    
    var nowPlayingViewController:NowPlayingViewController!
    
    var nowPlayingTapGestureRecognizer:UITapGestureRecognizer!
    var nowPlayingPanGestureRecognizer:UIPanGestureRecognizer!
    private var collapsedConstraint:NSLayoutConstraint!
    private var expandedConstraint:NSLayoutConstraint!
    
    private var collapsedBarLayoutGuide:UILayoutGuide!
    
    private var warningViewController:WarningViewController?
    private lazy var reducedAnimationDelegate = ReducedAnimationNavigationControllerDelegate()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let aelvc = AudioEntityLibraryViewController()
		aelvc.isBaseLevel = true
        let baseGroupIndex = UserDefaults.standard.integer(forKey: UserDefaultKeys.AllMusicBaseGroup)
        let selectedGroup = LibraryGrouping.allMusicGroupings[baseGroupIndex]
        aelvc.title = "ALL MUSIC"
        aelvc.sourceData = MediaQuerySourceData(filterQuery: selectedGroup.baseQuery, libraryGrouping: selectedGroup)
		
		libraryNavigationController = UINavigationController(rootViewController: aelvc)
		
        collapsedBarLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(collapsedBarLayoutGuide)
        collapsedBarLayoutGuide.heightAnchor.constraint(equalToConstant: type(of: self).miniPlayerHeight).isActive = true
        collapsedBarLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collapsedBarLayoutGuide.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        collapsedBarLayoutGuide.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        view.addSubview(libraryNavigationController.view)
        addChildViewController(libraryNavigationController)
        libraryNavigationController.didMove(toParentViewController: self)
        libraryNavigationController.navigationBar.backgroundColor = UIColor.clear
        libraryNavigationController.navigationBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        libraryNavigationController.navigationBar.shadowImage = UIImage()

        setNavigationDelegate()
        
        let libraryView = libraryNavigationController.view
        libraryView?.translatesAutoresizingMaskIntoConstraints = false
        libraryView?.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        lncBottomConstraint = libraryView?.bottomAnchor.constraint(equalTo: collapsedBarLayoutGuide.topAnchor)
        lncBottomConstraint.isActive = true
        libraryView?.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        libraryView?.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        nowPlayingViewController = NowPlayingViewController()
        
        let nowPlayingView = nowPlayingViewController.view
        view.insertSubview(nowPlayingView!, at: 0)
        view.bringSubview(toFront: nowPlayingView!)
        addChildViewController(nowPlayingViewController)
        nowPlayingViewController.didMove(toParentViewController: self)
        nowPlayingView?.translatesAutoresizingMaskIntoConstraints = false
        collapsedConstraint = nowPlayingView?.topAnchor.constraint(equalTo: collapsedBarLayoutGuide.topAnchor)
        collapsedConstraint.isActive = true
        expandedConstraint = nowPlayingView?.topAnchor.constraint(equalTo: view.topAnchor)
        
        nowPlayingView?.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        nowPlayingView?.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        nowPlayingView?.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true

        nowPlayingPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(RootViewController.handlePanGesture(_:)))
        nowPlayingPanGestureRecognizer.delegate = self
        nowPlayingViewController.view.addGestureRecognizer(self.nowPlayingPanGestureRecognizer)
        
        nowPlayingTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(RootViewController.handleTapGesture(_:)))
        nowPlayingTapGestureRecognizer.delegate = self
        nowPlayingViewController.view.addGestureRecognizer(self.nowPlayingTapGestureRecognizer)
    }
    
    //MARK: - Navigation controller delegate
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if !navigationController.isToolbarHidden {
            navigationController.isToolbarHidden = true
        }
    }
    
    func setNavigationDelegate() {
        let reduceAnimations = UserDefaults.standard.bool(forKey: UserDefaultKeys.ReduceAnimations)
        if reduceAnimations {
            libraryNavigationController.delegate = reducedAnimationDelegate
        } else {
            libraryNavigationController.delegate = self
        }
        (libraryNavigationController.topViewController as? CustomPopableViewController)?.enableCustomPopGestureRecognizer(reduceAnimations)
    }
    
    func presentWarningView(_ message:String, handler:@escaping ()->()) {
        if self.warningViewController != nil {
            Logger.debug("already displaying warning view")
            return
        }
        let warningVC = UIStoryboard.warningViewController()
        warningVC.handler = handler
        warningVC.message = message
        
        let warningView = warningVC.view
        warningView?.frame = CGRect(origin: collapsedBarLayoutGuide.layoutFrame.origin, size: CGSize(width: view.frame.width, height: 0))
        view.insertSubview(warningView!, belowSubview: nowPlayingViewController.view)
        warningViewController = warningVC
        
        warningView?.translatesAutoresizingMaskIntoConstraints = false
        lncBottomConstraint.isActive = false
        warningView?.topAnchor.constraint(equalTo: libraryNavigationController.view.bottomAnchor).isActive = true
        warningView?.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        warningView?.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        warningView?.heightAnchor.constraint(equalToConstant: 40).isActive = true
        warningView?.bottomAnchor.constraint(equalTo: collapsedBarLayoutGuide.topAnchor).isActive = true
        warningVC.warningButton.alpha = 0
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: UIViewAnimationOptions(), animations: { () -> Void in
            self.view.layoutIfNeeded()
            warningVC.warningButton.alpha = 1
            }, completion: nil)

    }
    
    func dismissWarningView() {
        guard let warningVC = self.warningViewController else {
            return
        }
        
        guard let heightConstraint = warningVC.view.constraints.filter({
            return $0.firstAttribute == NSLayoutAttribute.height && $0.firstItem === warningVC.view && $0.secondItem == nil
        }).first else { return }
        heightConstraint.constant = 0
        warningVC.warningButton.isHidden = true
        UIView.animate(withDuration: 0.15, delay: 0, options: UIViewAnimationOptions(), animations: { self.view.layoutIfNeeded() }, completion: {_ in
            warningVC.view.removeFromSuperview()
            self.lncBottomConstraint.isActive = true
            self.warningViewController = nil
        })
    }
    
    func pushViewController(_ vc:UIViewController) {
        if(pullableViewExpanded) {
            animatePullablePanel(shouldExpand: false)
        }
        libraryNavigationController.pushViewController(vc, animated: true)
    }
    
    func enableGesturesInSubViews(shouldEnable:Bool) {
        libraryNavigationController.view.isUserInteractionEnabled = shouldEnable
        nowPlayingViewController.view.isUserInteractionEnabled = shouldEnable
        sourceTableView?.scrollsToTop = shouldEnable
    }
    
    func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        let isDraggingUpward = (recognizer.velocity(in: view).y < 0)
        let currenyYPos = recognizer.view!.frame.origin.y
        
        let activeConstraint = expandedConstraint.isActive ? expandedConstraint : collapsedConstraint
        
        switch(recognizer.state) {
        case .changed:
            let translationY = recognizer.translation(in: self.view).y
            let endYPos = currenyYPos + translationY
            
            if(endYPos >= view.frame.minY && endYPos <= collapsedBarLayoutGuide.layoutFrame.minY) {
                activeConstraint?.constant += translationY

                recognizer.setTranslation(CGPoint.zero, in: view)
            }
        case .ended, .cancelled:
            if(nowPlayingViewController != nil) {
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
            return mediaItemViewController.sourceData
        }
        Logger.debug("Couldnt get a view controller with media items, returning nil")
        return nil
    }
    
    func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        if(!pullableViewExpanded) {
            animatePullablePanel(shouldExpand: true)
        }
    }
    
    func animatePullablePanel(shouldExpand:Bool) {
        if shouldExpand { //need to make sure one is deactivated before activating the other
            collapsedConstraint.isActive = false
            expandedConstraint.isActive = true
        } else {
            expandedConstraint.isActive = false
            collapsedConstraint.isActive = true
        }
        
        collapsedConstraint.constant = 0
        expandedConstraint.constant = 0
        
        pullableViewExpanded = shouldExpand
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    override var childViewControllerForStatusBarHidden: UIViewController? {
        return nowPlayingViewController
    }
    
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === nowPlayingPanGestureRecognizer {
            let translation = nowPlayingPanGestureRecognizer.translation(in: nowPlayingPanGestureRecognizer.view)
            return abs(translation.y) > abs(translation.x)
        }
        return true
    }
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return gestureRecognizer is UISwipeGestureRecognizer && otherGestureRecognizer === nowPlayingPanGestureRecognizer
	}
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return false
	}
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return gestureRecognizer === nowPlayingPanGestureRecognizer && otherGestureRecognizer is UISwipeGestureRecognizer
	}
}

private class ReducedAnimationNavigationControllerDelegate : NSObject, UINavigationControllerDelegate {
    
    private let transition = ViewControllerFadeAnimator.instance
    
    //MARK: - Navigation controller delegate
    @objc func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if !navigationController.isToolbarHidden {
            navigationController.isToolbarHidden = true
        }
    }
    
    @objc func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.operation = operation
        return transition
    }
    
    @objc func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if transition.interactive {
            return transition
        }
        return nil
    }
}
