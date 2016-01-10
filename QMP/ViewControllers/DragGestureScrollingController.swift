//
//  DragGestureScrollingController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/16/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

final class DragGestureScrollingController :NSObject {
    
    private let scrollView:UIScrollView
    private let offset:CGFloat = 50
    private let yTopOffset:CGFloat
    private let yBottomOffset:CGFloat
    
    private let delegate:LongPressToDragGestureHandler
    private let timeDelayInSeconds:Double = 0.005 //relates to smoothness
    private let maxScrollIncrement:CGFloat = 7
    private let minScrollIncrement:CGFloat = 0.005
    private var scrollIncrement:CGFloat
    
    private var visiblePosition:CGFloat!
    private var timer:NSTimer?
    private var gestureRecognizer:UILongPressGestureRecognizer!

    init(scrollView:UIScrollView, delegate:LongPressToDragGestureHandler) {
        self.scrollView = scrollView
        self.delegate = delegate
        self.yTopOffset = scrollView.contentInset.top + offset
        self.yBottomOffset = scrollView.frame.height - offset - scrollView.contentInset.bottom
        scrollIncrement = minScrollIncrement
    }
    
    deinit {
        timer?.invalidate()
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
            let speed = CGFloat((positionOffset/yTopOffset) * CGFloat(maxScrollIncrement))
            self.scrollIncrement = speed < 0.0 ? minScrollIncrement : speed
            
            if(timer == nil) {
                timer = NSTimer.scheduledTimerWithTimeInterval(timeDelayInSeconds,
                    target: self,
                    selector: "adjustScrollOffset",
                    userInfo: nil,
                    repeats: true)
            }
        } else {
            invalidateTimer()
            scrollIncrement = minScrollIncrement
        }
    }
    
    func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func adjustScrollOffset() {
        
        let originalYPosition = scrollView.contentOffset.y
        var newYPosition:CGFloat!
        if(visiblePosition <= yTopOffset && originalYPosition > (0 - scrollView.contentInset.top)) {
            newYPosition = originalYPosition - scrollIncrement
        } else if (visiblePosition >= yBottomOffset && originalYPosition < (scrollView.contentSize.height - scrollView.frame.height) + scrollView.contentInset.bottom){
            newYPosition = originalYPosition + scrollIncrement
        }
        
        if(newYPosition != nil) {
            scrollView.contentOffset.y = newYPosition
            delegate.handlePositionChange(gestureRecognizer)
        } else {
            invalidateTimer()
        }
    }
    
}


