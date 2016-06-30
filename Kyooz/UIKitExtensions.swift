//
//  UIKitExtensions.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/25/16.
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
    
    func constrainWidthToHeight(multiplier:CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraintEqualToAnchor(heightAnchor, multiplier: multiplier).active = true
    }
    
    func constrain(heightTo height:CGFloat, widthRatio multiplier:CGFloat) -> [Anchor : NSLayoutConstraint]{
        translatesAutoresizingMaskIntoConstraints = false
        return [
            .Height : heightAnchor.constraintEqualToConstant(height).activate(),
            .Width : widthAnchor.constraintEqualToAnchor(heightAnchor, multiplier: multiplier)
        ]
    }
    
    func constrain(widthTo width:CGFloat, heightRatio multiplier:CGFloat) -> [Anchor : NSLayoutConstraint]{
        translatesAutoresizingMaskIntoConstraints = false
        return [
            .Width : widthAnchor.constraintEqualToConstant(width).activate(),
            .Height : heightAnchor.constraintEqualToAnchor(widthAnchor, multiplier: multiplier).activate()
        ]
    }
    
    func constrain(heightTo height:CGFloat, widthTo width:CGFloat) -> [Anchor : NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        return [
            .Height : heightAnchor.constraintEqualToConstant(height).activate(),
            .Width : widthAnchor.constraintEqualToConstant(width).activate()
        ]
    }
    
}

extension NSLayoutConstraint {
    
    func activate() -> NSLayoutConstraint {
        active = true
        return self
    }
}

extension UIScreen {
    
    enum HeightClass {
        case iPhone4, iPhone5, iPhone6, iPhone6P
    }
    
    enum WidthClass {
        case iPhone345, iPhone6, iPhone6P
    }
    
    static var maxScreenLength:CGFloat {
        let bounds = mainScreen().bounds
        return max(bounds.width, bounds.height)
    }
    
    static var minScreenLength:CGFloat {
        let bounds = mainScreen().bounds
        return min(bounds.width, bounds.height)
    }
    
    static var heightClass : HeightClass {
        switch maxScreenLength {
        case 668...CGFloat.max:
            return .iPhone6P
        case 569...667:
            return .iPhone6
        case 568:
            return .iPhone5
        default:
            return .iPhone4
        }
    }
    
    static var widthClass : WidthClass {
        switch minScreenLength {
        case 376...CGFloat.max:
            return .iPhone6P
        case 321...375:
            return .iPhone6
        default:
            return .iPhone345
        }
    }
    
    
}


extension UITableView {
    
    func selectAll() {
        for section in 0 ..< numberOfSections {
            for row in 0 ..< numberOfRowsInSection(section) {
                let indexPath = NSIndexPath(forRow: row, inSection: section)
                selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
            }
        }
    }
    
    func deselectAll() {
        indexPathsForSelectedRows?.forEach() {
            deselectRowAtIndexPath($0, animated: false)
        }
    }
    
    func selectOrDeselectAll() {
        guard (editing && allowsMultipleSelectionDuringEditing) || allowsMultipleSelection else { return }
        
        if indexPathsForSelectedRows != nil {
            deselectAll()
        } else {
            selectAll()
        }
    }
    
}

extension UIBarButtonItem {
    
    static func flexibleSpace() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
    }
    
}

extension UINavigationBar {
	
	func clearBackgroundImage() {
		let image = UIImage()
		setBackgroundImage(image, forBarMetrics: .Default)
		shadowImage = image
	}
}

