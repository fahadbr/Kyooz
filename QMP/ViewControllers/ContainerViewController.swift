//
//  ContainerViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/15/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class ContainerViewController : UIViewController {
    
    let centerPanelExpandedOffset:CGFloat = 60
    
    var tapGestureRecognizer:UITapGestureRecognizer!
    
    var rootNavigationControler:UINavigationController!
    var rootViewController:UIViewController!
    
    var sidePanelViewController:UIViewController?
    
    var sidePanelExpanded:Bool = false {
        didSet {
            showShadowForCenterViewController(sidePanelExpanded)
            tapGestureRecognizer.enabled = sidePanelExpanded
        }
    }
    
    
    @IBAction func unwindToBrowser(segue : UIStoryboardSegue)  {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.rootViewController = UIStoryboard.rootViewController()
        
        self.rootNavigationControler = UINavigationController(rootViewController: self.rootViewController)
        self.rootNavigationControler.navigationBarHidden = true
        self.rootNavigationControler.toolbarHidden = false
        self.view.addSubview(rootNavigationControler.view)
        self.addChildViewController(rootNavigationControler)
        
        self.rootNavigationControler.didMoveToParentViewController(self)
        let panGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "handlePanGesture:")
        panGestureRecognizer.edges = UIRectEdge.Right
        rootNavigationControler.view.addGestureRecognizer(panGestureRecognizer)
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTouchGesture:")
        
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func toggleSidePanel() {
        if(!sidePanelExpanded) {
            self.addSidePanelViewController()
        }
        animateSidePanel(shouldExpand: !sidePanelExpanded)
    }
    
    func showShadowForCenterViewController(shouldShowShadow:Bool) {
        if(shouldShowShadow) {
            self.rootNavigationControler.view.layer.shadowOpacity = 0.8
        } else {
            self.rootNavigationControler.view.layer.shadowOpacity = 0.0
        }
    }
    
    func addSidePanelViewController() {
        if(self.sidePanelViewController == nil) {
            self.sidePanelViewController = UIStoryboard.nowPlayingViewController()
            
            let originalFrame = sidePanelViewController!.view.frame
            let newWidth = CGRectGetWidth(self.view.frame) - centerPanelExpandedOffset
            let newHeight = originalFrame.height
            let newX = originalFrame.origin.x + centerPanelExpandedOffset
            let newY = originalFrame.origin.y
            
            self.sidePanelViewController?.view.frame = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
            self.view.insertSubview(sidePanelViewController!.view, atIndex: 0)
            self.addChildViewController(sidePanelViewController!)
            self.sidePanelViewController!.didMoveToParentViewController(self)
        }
    }
    
    func animateSidePanel(#shouldExpand: Bool) {
        if(shouldExpand) {
            sidePanelExpanded = true
            
            animateCenterPanelXPosition(targetPosition: -CGRectGetWidth(rootNavigationControler.view.frame) +
                centerPanelExpandedOffset)
            
        } else {
            animateCenterPanelXPosition(targetPosition: 0) { finished in
                self.sidePanelExpanded = false
                
                self.sidePanelViewController!.view.removeFromSuperview()
                self.sidePanelViewController = nil
            }
        }
    }
    
    func animateCenterPanelXPosition(#targetPosition:CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: .CurveEaseInOut,
            animations: {self.rootNavigationControler.view.frame.origin.x = targetPosition},
            completion: completion)
    }
    
    // MARK: Gesture recognizer
    
    func handleTouchGesture(recognizer:UITapGestureRecognizer) {
        if(recognizer.state == .Ended) {
            let touchX = recognizer.locationInView(self.view).x
            if(touchX <= centerPanelExpandedOffset && sidePanelExpanded) {
                self.toggleSidePanel()
            }
        }
    }
    
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let gestureIsDraggingFromLeftToRight = (recognizer.velocityInView(view).x > 0)

        
        switch(recognizer.state) {
        case .Began:
            if(!sidePanelExpanded && !gestureIsDraggingFromLeftToRight) {
                addSidePanelViewController()
            }
            
            showShadowForCenterViewController(true)
        case .Changed:
            recognizer.view!.center.x = recognizer.view!.center.x + recognizer.translationInView(view).x
            recognizer.setTranslation(CGPointZero, inView: view)
        case .Ended:
            if(sidePanelViewController != nil) {
                let hasMovedGreaterThanHalfway = recognizer.view!.center.x < 0
                animateSidePanel(shouldExpand: hasMovedGreaterThanHalfway)
            }
        case .Cancelled:
            if(sidePanelViewController != nil) {
                let hasMovedGreaterThanHalfway = recognizer.view!.center.x < 0
                animateSidePanel(shouldExpand: hasMovedGreaterThanHalfway)
            }
        default:
            break
        
        }
        
    }
    
}
