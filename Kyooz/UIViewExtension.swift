//
//  UIViewExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/1/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

enum Anchor:Int {
	static let standardAnchors:[Anchor] = [.Top, .Bottom, .Left, .Right]
	
	case Top, Bottom, Left, Right, CenterX, CenterY, Width, Height
	
}

extension UIView {
	
	func add(subView subView:UIView, with anchors:[Anchor]) -> [Anchor : NSLayoutConstraint] {
		return ConstraintUtils.applyConstraintsToView(withAnchors: anchors, subView: subView, parentView: self)
	}
	
	func constrainWidthToHeight(multiplier:CGFloat = 1) {
		translatesAutoresizingMaskIntoConstraints = false
		widthAnchor.constraintEqualToAnchor(heightAnchor, multiplier: multiplier).active = true
	}
	
	func constrain(height height:CGFloat, widthRatio multiplier:CGFloat = 1) -> [Anchor : NSLayoutConstraint]{
		translatesAutoresizingMaskIntoConstraints = false
		return [
			.Height : heightAnchor.constraintEqualToConstant(height).activate(),
			.Width : widthAnchor.constraintEqualToAnchor(heightAnchor, multiplier: multiplier)
		]
	}
	
	func constrain(width width:CGFloat, heightRatio multiplier:CGFloat = 1) -> [Anchor : NSLayoutConstraint]{
		translatesAutoresizingMaskIntoConstraints = false
		return [
			.Width : widthAnchor.constraintEqualToConstant(width).activate(),
			.Height : heightAnchor.constraintEqualToAnchor(widthAnchor, multiplier: multiplier).activate()
		]
	}
	
	func constrain(height height:CGFloat, width:CGFloat) -> [Anchor : NSLayoutConstraint] {
		translatesAutoresizingMaskIntoConstraints = false
		return [
			.Height : heightAnchor.constraintEqualToConstant(height).activate(),
			.Width : widthAnchor.constraintEqualToConstant(width).activate()
		]
	}
	
}