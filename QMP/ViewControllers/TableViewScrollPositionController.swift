//
//  TableViewScrollPositionController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/16/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

class TableViewScrollPositionController :NSObject {
    
    private let tableView:UITableView
    private let offset:CGFloat = 100.0
    private let yTopOffset:CGFloat
    private let yBottomOffset:CGFloat
    private let maxTimeDelay = 0.01
    private let minTimeDelay = 0.0005
    private let scrollSpeed:CGFloat = 2
    private let delegate:TableViewScollPositionControllerDelegate
    private let updatesDataSource:Bool
    
    private var visiblePosition:CGFloat!
    private var timeDelayInSeconds:Double!
    private var timer:NSTimer!
    private var gestureRecognizer:UILongPressGestureRecognizer!

    init(tableView:UITableView, delegate:TableViewScollPositionControllerDelegate, updatesDataSource:Bool) {
        self.tableView = tableView
        self.delegate = delegate
        self.updatesDataSource = updatesDataSource
        self.yTopOffset = tableView.contentInset.top + offset
        self.yBottomOffset = tableView.frame.height - offset - tableView.contentInset.bottom
        Logger.debug("contentInset top: \(tableView.contentInset.top) bottom:\(tableView.contentInset.bottom)")
        self.timeDelayInSeconds = maxTimeDelay
    }
    
    deinit {
        timer?.invalidate()
        Logger.debug("deinitializing table view scroll position controller")
    }
    
    func startScrollingWithLocation(location: CGPoint, gestureRecognizer:UILongPressGestureRecognizer) {
        self.visiblePosition = location.y - tableView.contentOffset.y
        self.gestureRecognizer = gestureRecognizer
        
        var positionOffset:CGFloat!
        timer?.invalidate()
        if(visiblePosition <= yTopOffset) {
            positionOffset = yTopOffset - visiblePosition
        } else if (visiblePosition >= yBottomOffset) {
            positionOffset = visiblePosition - yBottomOffset
        }
        if(positionOffset != nil) {
            positionOffset = positionOffset <= 0.0 ? 0.0 : positionOffset
            let timeDelay = Double((1.0 - (positionOffset/yTopOffset)) * CGFloat(maxTimeDelay))
            timeDelayInSeconds = timeDelay < 0.0 ? minTimeDelay : timeDelay
            timer = NSTimer.scheduledTimerWithTimeInterval(timeDelayInSeconds,
                target: self,
                selector: "adjustScrollOffset:",
                userInfo: nil,
                repeats: true)
        } else {
            timeDelayInSeconds = maxTimeDelay
            timer = nil
        }
    }
    
    func invalidateTimer() {
        timer?.invalidate()
    }
    
    func adjustScrollOffset(sender:NSTimer?) {
        
        let origContentOffset = tableView.contentOffset
        var newOffset:CGPoint!
        if(visiblePosition <= yTopOffset && tableView.contentOffset.y > (0 - tableView.contentInset.top)) {
            newOffset = CGPoint(x: origContentOffset.x, y: (origContentOffset.y - scrollSpeed))
        } else if (visiblePosition >= yBottomOffset && tableView.contentOffset.y < (tableView.contentSize.height - tableView.frame.height) + tableView.contentInset.bottom){
            newOffset = CGPoint(x: origContentOffset.x, y: (origContentOffset.y + scrollSpeed))
        }
        
        if(newOffset != nil) {
            tableView.setContentOffset(newOffset, animated: false)
            delegate.handlePositionChange(gestureRecognizer, updateDataSource:updatesDataSource)
        } else {
            timer?.invalidate()
        }
    }
    
}

protocol TableViewScollPositionControllerDelegate {
    func handlePositionChange(sender:UILongPressGestureRecognizer, updateDataSource:Bool) -> CGPoint?
}

