//
//  ConstraintUtils.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/9/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

struct ConstraintUtils {
	
	static func applyStandardConstraintsToView(subView:UIView, parentView:UIView, shouldActivate:Bool = true) -> [Anchor:NSLayoutConstraint] {
		return applyConstraintsToView(withAnchors: [.top, .bottom, .left, .right], subView: subView, parentView: parentView, shouldActivate: shouldActivate)
	}
    
    static func applyConstraintsToView(withAnchors anchors:[Anchor], subView:UIView, parentView:UIView, shouldActivate:Bool = true) -> [Anchor:NSLayoutConstraint] {
        parentView.addSubview(subView)
        subView.translatesAutoresizingMaskIntoConstraints = false
        var constraintDict = [Anchor:NSLayoutConstraint]()
        for anchor:Anchor in anchors{
            constraintDict[anchor] = shouldActivate ? activeConstraintForAnchor(anchor, subView: subView, parentView: parentView) : constraintForAnchor(anchor, subView: subView, parentView: parentView)
        }
        return constraintDict
    }
	
	static func activeConstraintForAnchor(_ anchor:Anchor, subView:UIView, parentView:UIView) -> NSLayoutConstraint {
		let constraint = constraintForAnchor(anchor, subView: subView, parentView: parentView)
		constraint.isActive = true
		return constraint
	}
	
	static func constraintForAnchor(_ anchor:Anchor, subView:UIView, parentView:UIView) -> NSLayoutConstraint {
		switch anchor {
		case .top:
			return subView.topAnchor.constraint(equalTo: parentView.topAnchor)
		case .bottom:
			return subView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
		case .left:
			return subView.leftAnchor.constraint(equalTo: parentView.leftAnchor)
		case .right:
			return subView.rightAnchor.constraint(equalTo: parentView.rightAnchor)
        case .centerX:
            return subView.centerXAnchor.constraint(equalTo: parentView.centerXAnchor)
        case .centerY:
            return subView.centerYAnchor.constraint(equalTo: parentView.centerYAnchor)
		case .height:
			return subView.heightAnchor.constraint(equalTo: parentView.heightAnchor)
		case .width:
			return subView.widthAnchor.constraint(equalTo: parentView.widthAnchor)
		}
		
	}
	
}
