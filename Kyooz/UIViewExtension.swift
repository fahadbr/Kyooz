//
//  UIViewExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/1/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

enum Anchor:Int {
	static let standardAnchors:[Anchor] = [.top, .bottom, .left, .right]
	
	case top, bottom, left, right, centerX, centerY, width, height
	
}

extension UIView {
	
	func add(subView:UIView, with anchors: Anchor...) -> [Anchor : NSLayoutConstraint] {
		return ConstraintUtils.applyConstraintsToView(withAnchors: anchors, subView: subView, parentView: self)
	}
    
    func add(subView:UIView, with anchors: [Anchor]) -> [Anchor : NSLayoutConstraint] {
        return ConstraintUtils.applyConstraintsToView(withAnchors: anchors, subView: subView, parentView: self)
    }
	
	func constrainWidthToHeight(_ multiplier:CGFloat = 1) {
		translatesAutoresizingMaskIntoConstraints = false
		widthAnchor.constraint(equalTo: heightAnchor, multiplier: multiplier).isActive = true
	}
	
	func constrain(height:CGFloat, widthRatio multiplier:CGFloat = 1) -> [Anchor : NSLayoutConstraint]{
		translatesAutoresizingMaskIntoConstraints = false
		return [
			.height : heightAnchor.constraint(equalToConstant: height).activate(),
			.width : widthAnchor.constraint(equalTo: heightAnchor, multiplier: multiplier)
		]
	}
	
	func constrain(width:CGFloat, heightRatio multiplier:CGFloat = 1) -> [Anchor : NSLayoutConstraint]{
		translatesAutoresizingMaskIntoConstraints = false
		return [
			.width : widthAnchor.constraint(equalToConstant: width).activate(),
			.height : heightAnchor.constraint(equalTo: widthAnchor, multiplier: multiplier).activate()
		]
	}
	
	func constrain(height:CGFloat, width:CGFloat) -> [Anchor : NSLayoutConstraint] {
		translatesAutoresizingMaskIntoConstraints = false
		return [
			.height : heightAnchor.constraint(equalToConstant: height).activate(),
			.width : widthAnchor.constraint(equalToConstant: width).activate()
		]
	}
	
}
