//
//  KyoozTableFooterView.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/28/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class KyoozTableFooterView: UIView {
	
	private static let font = UIFont(name:ThemeHelper.defaultFontName, size: ThemeHelper.defaultFontSize)
	
	var text:String? {
		get {
			return label.text
		} set {
			label.text = newValue
			label.frame.size = label.intrinsicContentSize()
			frame.size = CGSize(width: label.frame.width, height: label.frame.height + 25)
			layoutSubviews()
		}
	}
	
	private let label = UILabel()
//	private let separatorLayer = CAShapeLayer()
	
	init() {
		super.init(frame: CGRect.zero)
		addSubview(label)
		label.textColor = UIColor.darkGrayColor()
		label.textAlignment = .Center
		label.numberOfLines = 0
		label.lineBreakMode = .ByWordWrapping
		label.font = self.dynamicType.font
		
//		separatorLayer.strokeColor = UIColor.darkGrayColor().CGColor
//		separatorLayer.lineWidth = 0.5
//		layer.addSublayer(separatorLayer)
	}
	
	override func layoutSubviews() {
		let path = UIBezierPath()
		path.moveToPoint(bounds.origin)
		path.addLineToPoint(CGPoint(x: bounds.maxX, y: bounds.origin.y))
		path.applyTransform(CGAffineTransformMakeTranslation(0, 10))
//		separatorLayer.frame = bounds
//		separatorLayer.path = path.CGPath
		
		label.center = CGPoint(x:bounds.midX, y: bounds.midY)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}
