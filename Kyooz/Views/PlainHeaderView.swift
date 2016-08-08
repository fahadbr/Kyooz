//
//  PlainHeaderView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/20/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class PlainHeaderView : UIVisualEffectView {
	
	private var path:UIBezierPath!
	private var accentLayer:CAShapeLayer = CAShapeLayer()
    
	init() {
        super.init(effect: UIBlurEffect(style: .dark))
		accentLayer.strokeColor = ThemeHelper.defaultVividColor.cgColor
		accentLayer.lineWidth = 0.75
		layer.addSublayer(accentLayer)
    }
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
    
    override func layoutSubviews() {
		path = UIBezierPath()
		path.move(to: CGPoint(x: bounds.origin.x, y: bounds.height))
		path.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
		accentLayer.path = path.cgPath
    }
	
}
