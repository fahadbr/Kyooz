//
//  WhatsNewDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class WhatsNewDelegate : KyoozOptionsViewControllerDelegate {
    
    typealias This = WhatsNewDelegate
    
    
    static var sizeConstraint: SizeConstraint {
        return SizeConstraint(maxHeight: UIScreen.mainScreen().bounds.height * 0.95,
                              maxWidth: UIScreen.mainScreen().bounds.width * 0.75,
                              minHeight: 0,
                              minWidth: 0)
    }
    
    let sizeConstraint: SizeConstraint = This.sizeConstraint
    let headerView: UIView
    
    init() throws {
        headerView = try UITextView(fileName: "ChangeLog", documentType: .html)
        headerView.frame.size = sizeConstraint.maxSize
    }
    
    
    func animation(forView view: UIView) -> CAAnimation {
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.duration = 0.4
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.fromValue = view.frame.height * 1.5
        animation.fillMode = kCAFillModeBackwards
        return CAAnimation()
    }
    
    
}
