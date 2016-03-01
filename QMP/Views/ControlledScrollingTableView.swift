//
//  ControlledScrollingTableView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/28/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class ControlledScrollingTableView : UITableView {
    
    var canScroll = true {
        didSet {
            Logger.debug("table view can scroll = \(self.canScroll)")
        }
    }
    
    var extendedContentSize:CGFloat = 0 {
        didSet {
            previousContentHeight = 0
            setNeedsLayout()
        }
    }
    
    private var count:Int = 0
    private var interval:Int = 1
    
    private var previousContentHeight:CGFloat = 0
    
    override func layoutSubviews() {

        if !canScroll {
            let mod = ++count%interval
//            Logger.debug("mod = \(mod)")
            if mod == 0 {
//                Logger.debug("resetting content offset")
                let delegate = self.delegate
                self.delegate = nil
                self.contentOffset.y = 0
//                self.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
                self.delegate = delegate
            }
        }
        super.layoutSubviews()
        let height = self.contentSize.height
        
        if height != previousContentHeight {
            applynewsize(height)
        }

    }
    
    private func applynewsize(height:CGFloat) {
        Logger.debug("content size before \(height)")
        let newHeight = height + extendedContentSize
        contentSize.height = newHeight
        previousContentHeight = newHeight
        Logger.debug("content size after \(newHeight)")
    }
    
    
}
