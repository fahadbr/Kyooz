//
//  UtilHeaderViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/16/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class UtilHeaderViewController: HeaderViewController {

	private var path:UIBezierPath!
	private var accentLayer:CAShapeLayer = CAShapeLayer()
	
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clearColor()
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        ConstraintUtils.applyStandardConstraintsToView(subView: blurView, parentView: view)
        view.sendSubviewToBack(blurView)
        
        accentLayer.strokeColor = ThemeHelper.defaultVividColor.CGColor
        accentLayer.lineWidth = 0.75
        view.layer.addSublayer(accentLayer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
		path = UIBezierPath()
		path.moveToPoint(CGPoint(x: view.bounds.origin.x, y: view.bounds.height))
		path.addLineToPoint(CGPoint(x: view.bounds.width, y: view.bounds.height))
		accentLayer.path = path.CGPath
    }
    
}


final class NowPlayingHeaderViewController : UtilHeaderViewController {
	
	override func createLeftButton() -> UIButton {
		let b = UIButton()
		b.contentMode = .ScaleAspectFit
		b.setImage(UIImage(instance:.Trash), forState: .Normal)
		b.setImage(UIImage(highlightedInstance:.Trash), forState: .Highlighted)
		return b
	}
	
	
}