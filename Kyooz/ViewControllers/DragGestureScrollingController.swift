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

    private static let offset:CGFloat = 50
    private static let maxScrollIncrement:CGFloat = 50
    private static let minScrollIncrement:CGFloat = 0.005
    
    private let scrollView:UIScrollView

    private let scrollOffsetTop:CGFloat
    private let scrollOffsetBottom:CGFloat
    private let minContentOffset:CGFloat
    private var maxContentOffset:CGFloat {
        //calculating the maxContentOffset each time because the contentSize is subject to change
        //TODO: possibly add observer for contentSize
        return (scrollView.contentSize.height - scrollView.bounds.height) + scrollView.contentInset.bottom
    }
    
    private let delegate:LongPressToDragGestureHandler


    private var scrollIncrement:CGFloat = DragGestureScrollingController.minScrollIncrement
    
    private var visiblePosition:CGFloat!
    private var displayLink:CADisplayLink?
    private var gestureRecognizer:UILongPressGestureRecognizer!
    private var isScrollingUp:Bool = false

    init(scrollView:UIScrollView, delegate:LongPressToDragGestureHandler) {
        self.scrollView = scrollView
        self.delegate = delegate
        
        scrollOffsetTop = scrollView.contentInset.top + self.dynamicType.offset
        scrollOffsetBottom = scrollView.frame.height - self.dynamicType.offset - scrollView.contentInset.bottom
        minContentOffset = -scrollView.contentInset.top
    }
    
    deinit {
        displayLink?.invalidate()
    }
    
    func startScrollingWithLocation(_ location: CGPoint, gestureRecognizer:UILongPressGestureRecognizer) {
        visiblePosition = location.y - scrollView.contentOffset.y
        self.gestureRecognizer = gestureRecognizer
        
        var positionOffset:CGFloat

        if(visiblePosition <= scrollOffsetTop) {
            positionOffset = scrollOffsetTop - visiblePosition
            isScrollingUp = true
        } else if (visiblePosition >= scrollOffsetBottom) {
            positionOffset = visiblePosition - scrollOffsetBottom
            isScrollingUp = false
        } else {
            invalidateDisplayLink()
            scrollIncrement = self.dynamicType.minScrollIncrement
            return
        }
        
        let scrollIncrementForFraction:CGFloat = (max(positionOffset, 0.0)/scrollOffsetTop) * self.dynamicType.maxScrollIncrement
        scrollIncrement = max(self.dynamicType.minScrollIncrement, scrollIncrementForFraction)
        
        if(displayLink == nil) {
            let displayLink = CADisplayLink(target: self, selector: #selector(DragGestureScrollingController.adjustScrollOffset))
            displayLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
            self.displayLink = displayLink
        }

    }
    
    func invalidateDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    func adjustScrollOffset() {
        let currentOffset = scrollView.contentOffset.y
        let newOffset:CGFloat
        
        let maxContentOffset = self.maxContentOffset
        if isScrollingUp {
            newOffset = max(currentOffset - scrollIncrement, minContentOffset)
        } else {
            newOffset = min(currentOffset + scrollIncrement, maxContentOffset)
        }
        
        guard newOffset <= maxContentOffset && newOffset >= minContentOffset else {
            invalidateDisplayLink()
            return
        }
        
        //THIS ORDER MATTERS FOR DRAG AND DROP
        //(When scrolling fast the tableview datasource may sometimes return the placeholder cell because of the updated indexPathOfMovingItem)
        _ = delegate.handlePositionChange(gestureRecognizer)
        scrollView.contentOffset.y = newOffset
        
    }
    
}


