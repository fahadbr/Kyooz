//
//  DragGestureScrollingController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/16/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

class DragGestureScrollingController :NSObject {
    
    private let scrollView:UIScrollView
    private let offset:CGFloat = 100.0
    private let yTopOffset:CGFloat
    private let yBottomOffset:CGFloat
    
    private let delegate:DragGestureScrollingControllerDelegate
    private let timeDelayInSeconds:Double = 0.005 //relates to smoothness
    private let maxScrollSpeed:CGFloat = 7
    private let minScrollSpeed:CGFloat = 0.005
    private var scrollSpeed:CGFloat
    
    private var visiblePosition:CGFloat!
    private var timer:NSTimer?
    private var gestureRecognizer:UILongPressGestureRecognizer!

    init(scrollView:UIScrollView, delegate:DragGestureScrollingControllerDelegate) {
        self.scrollView = scrollView
        self.delegate = delegate
        self.yTopOffset = scrollView.contentInset.top + offset
        self.yBottomOffset = scrollView.frame.height - offset - scrollView.contentInset.bottom
        Logger.debug("contentInset top: \(scrollView.contentInset.top) bottom:\(scrollView.contentInset.bottom)")
        scrollSpeed = minScrollSpeed
    }
    
    deinit {
        timer?.invalidate()
        Logger.debug("deinitializing table view scroll position controller")
    }
    
    func startScrollingWithLocation(location: CGPoint, gestureRecognizer:UILongPressGestureRecognizer) {
        self.visiblePosition = location.y - scrollView.contentOffset.y
        self.gestureRecognizer = gestureRecognizer
        
        var positionOffset:CGFloat!

        if(visiblePosition <= yTopOffset) {
            positionOffset = yTopOffset - visiblePosition
        } else if (visiblePosition >= yBottomOffset) {
            positionOffset = visiblePosition - yBottomOffset
        }
        if(positionOffset != nil) {
            positionOffset = positionOffset <= 0.0 ? 0.0 : positionOffset
            let speed = CGFloat((positionOffset/yTopOffset) * CGFloat(maxScrollSpeed))
            self.scrollSpeed = speed < 0.0 ? minScrollSpeed : speed
            
            if(timer == nil) {
                timer = NSTimer.scheduledTimerWithTimeInterval(timeDelayInSeconds,
                    target: self,
                    selector: "adjustScrollOffset:",
                    userInfo: nil,
                    repeats: true)
            }
        } else {
            invalidateTimer()
            scrollSpeed = minScrollSpeed
        }
    }
    
    func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func adjustScrollOffset(sender:NSTimer?) {
        
        let originalYPosition = scrollView.contentOffset.y
        var newYPosition:CGFloat!
        if(visiblePosition <= yTopOffset && originalYPosition > (0 - scrollView.contentInset.top)) {
            newYPosition = originalYPosition - scrollSpeed
        } else if (visiblePosition >= yBottomOffset && originalYPosition < (scrollView.contentSize.height - scrollView.frame.height) + scrollView.contentInset.bottom){
            newYPosition = originalYPosition + scrollSpeed
        }
        
        if(newYPosition != nil) {
            scrollView.contentOffset.y = newYPosition
            delegate.handlePositionChange(gestureRecognizer)
        } else {
            invalidateTimer()
        }
    }
    
}

protocol DragGestureScrollingControllerDelegate {
    func handlePositionChange(sender:UILongPressGestureRecognizer) -> CGPoint?
}

