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
        view.backgroundColor = UIColor.clear
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        ConstraintUtils.applyStandardConstraintsToView(subView: blurView, parentView: view)
        view.sendSubview(toBack: blurView)
        
        accentLayer.strokeColor = ThemeHelper.defaultVividColor.cgColor
        accentLayer.lineWidth = 0.75
        view.layer.addSublayer(accentLayer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
		path = UIBezierPath()
		path.move(to: CGPoint(x: view.bounds.origin.x, y: view.bounds.height))
		path.addLine(to: CGPoint(x: view.bounds.width, y: view.bounds.height))
		accentLayer.path = path.cgPath
    }
    
}

