//
//  RootViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/15/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class RootViewController: UIViewController {
    
    static let instance:RootViewController = RootViewController()
    
    static let nowPlayingViewCollapsedOffset:CGFloat = 55

    var nowPlayingViewOrigin:CGPoint!
    var pullableViewExpanded:Bool  {
        get {
            return nowPlayingSummaryViewController.expanded
        } set {
            nowPlayingSummaryViewController.expanded = newValue
            nowPlayingTapGestureRecognizer.enabled = !newValue
            UIApplication.sharedApplication().setStatusBarStyle(newValue ? UIStatusBarStyle.LightContent : UIStatusBarStyle.Default, animated: true)
        }
    }
    
    var libraryNavigationController:UINavigationController!
    

    var nowPlayingSummaryViewController:NowPlayingSummaryViewController!
    
    var nowPlayingTapGestureRecognizer:UITapGestureRecognizer!
    var nowPlayingPanGestureRecognizer:UIPanGestureRecognizer!
    var gestureDelegate:UIGestureRecognizerDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.libraryNavigationController = UIStoryboard.libraryNavigationController()
        let originalFrame = self.libraryNavigationController.view.frame
        let newOrigin = originalFrame.origin
        let newSize = CGSize(width: CGRectGetWidth(originalFrame), height: originalFrame.height - RootViewController.nowPlayingViewCollapsedOffset)
        self.libraryNavigationController.view.frame = CGRect(origin: newOrigin, size: newSize)
        
        self.view.addSubview(libraryNavigationController.view)
        self.addChildViewController(libraryNavigationController)
        self.libraryNavigationController.didMoveToParentViewController(self)
        
        self.nowPlayingSummaryViewController = UIStoryboard.nowPlayingSummaryViewController()
        self.nowPlayingViewOrigin = CGPoint(x: 0, y: self.view.frame.height - RootViewController.nowPlayingViewCollapsedOffset)

        self.view.addSubview(nowPlayingSummaryViewController.view)
        self.addChildViewController(nowPlayingSummaryViewController)
        self.nowPlayingSummaryViewController.didMoveToParentViewController(self)
        
        self.nowPlayingPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        self.nowPlayingPanGestureRecognizer.delegate = gestureDelegate
        self.nowPlayingSummaryViewController.view.addGestureRecognizer(self.nowPlayingPanGestureRecognizer)
        
        self.nowPlayingTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTapGesture:")
        self.nowPlayingTapGestureRecognizer.delegate = gestureDelegate
        self.nowPlayingSummaryViewController.view.addGestureRecognizer(self.nowPlayingTapGestureRecognizer)
        
        //explicitly setting this here
        self.pullableViewExpanded = false
        self.animatePullablePanel(shouldExpand: false)
    }

    func enableGesturesInSubViews(#shouldEnable:Bool) {
        self.libraryNavigationController.interactivePopGestureRecognizer.enabled = shouldEnable
        self.nowPlayingPanGestureRecognizer.enabled = shouldEnable
        self.nowPlayingTapGestureRecognizer.enabled = shouldEnable
    }
    
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let isDraggingUpward = (recognizer.velocityInView(view).y < 0)
        let currenyYPos = recognizer.view!.frame.origin.y
        
        switch(recognizer.state) {
        case .Began:
            println("NPSVC Pan Gesture Began")
        case .Changed:
            let translationY = recognizer.translationInView(self.view).y
            let endYPos = currenyYPos + translationY
            
            if(endYPos >= 0 && endYPos <= self.nowPlayingViewOrigin.y) {
                recognizer.view!.center.y = recognizer.view!.center.y + translationY
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
    
    func handleTapGesture(recognizer: UITapGestureRecognizer) {
        if(!pullableViewExpanded) {
            animatePullablePanel(shouldExpand: true)
        }
    }
    
    func animatePullablePanel(#shouldExpand:Bool) {
        if(shouldExpand) {
            pullableViewExpanded = true
            
            animatePullablePanelYPosition(targetPosition: 0)
            
        } else {
            animatePullablePanelYPosition(targetPosition: nowPlayingViewOrigin.y) { finished in
                self.pullableViewExpanded = false
                
            }
        }
    }
    
    
    func animatePullablePanelYPosition(#targetPosition:CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: .CurveEaseInOut,
            animations: {self.nowPlayingSummaryViewController.view.frame.origin.y = targetPosition},
            completion: completion)
        
    }


}
