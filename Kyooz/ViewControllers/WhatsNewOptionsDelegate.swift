//
//  WhatsNewDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

func whatsNewViewController() throws -> KyoozOptionsViewController {
	let op = BasicKyoozOptionsProvider(options:
		KyoozMenuAction(title: "Rate in AppStore") {
			return
		},
	   KyoozMenuAction(title: "No Thanks")
	)
	
	
	return KyoozOptionsViewController(optionsProviders: [op],
	                                  delegate: try WhatsNewOptionsDelegate())
}

class WhatsNewOptionsDelegate : KyoozOptionsViewControllerDelegate {
    
    typealias This = WhatsNewOptionsDelegate
    
    
    static var sizeConstraint: SizeConstraint {
        return SizeConstraint(maxHeight: UIScreen.mainScreen().bounds.height * 0.95,
                              maxWidth: UIScreen.mainScreen().bounds.width * 0.95,
                              minHeight: 0,
                              minWidth: 0)
    }
    
    let sizeConstraint: SizeConstraint = This.sizeConstraint
    let headerView: UIView
    
    init() throws {
        headerView = try UITextView(fileName: "ChangeLog", documentType: .html)
        headerView.frame.size = CGSize(width: sizeConstraint.maxWidth, height: sizeConstraint.maxHeight * 0.75)
    }
    
    
    func animation(forView view: UIView) -> CAAnimation {
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.3, 0.8, 0.4, 0.9)
        animation.fromValue = view.frame.height * 1.5
        animation.fillMode = kCAFillModeBackwards
        return animation
    }
    
    
}
