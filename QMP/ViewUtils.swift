//
//  ViewUtils.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/9/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

struct ViewUtils {
	
	enum Anchor:Int { case Top, Bottom, Left, Right }
	
	static func applyStandardConstraintsToView(subView subView:UIView, parentView:UIView, shouldActivate:Bool = true) -> [Anchor:NSLayoutConstraint] {
		
		parentView.addSubview(subView)
		subView.translatesAutoresizingMaskIntoConstraints = false
		var constraintDict = [Anchor:NSLayoutConstraint]()
		for anchor:Anchor in [.Top, .Bottom, .Left, .Right] {
			constraintDict[anchor] = shouldActivate ? activeConstraintForAnchor(anchor, subView: subView, parentView: parentView) : constraintForAnchor(anchor, subView: subView, parentView: parentView)
		}
		return constraintDict
	}
	
	static func activeConstraintForAnchor(anchor:Anchor, subView:UIView, parentView:UIView) -> NSLayoutConstraint {
		let constraint = constraintForAnchor(anchor, subView: subView, parentView: parentView)
		constraint.active = true
		return constraint
	}
	
	static func constraintForAnchor(anchor:Anchor, subView:UIView, parentView:UIView) -> NSLayoutConstraint {
		switch anchor {
		case .Top:
			return subView.topAnchor.constraintEqualToAnchor(parentView.topAnchor)
		case .Bottom:
			return subView.bottomAnchor.constraintEqualToAnchor(parentView.bottomAnchor)
		case .Left:
			return subView.leftAnchor.constraintEqualToAnchor(parentView.leftAnchor)
		case .Right:
			return subView.rightAnchor.constraintEqualToAnchor(parentView.rightAnchor)
		}
		
	}
	
}
