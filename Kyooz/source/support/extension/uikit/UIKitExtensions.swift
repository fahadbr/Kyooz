//
//  UIKitExtensions.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/25/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit



extension NSLayoutConstraint {
    
    func activate() -> NSLayoutConstraint {
        isActive = true
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
        let bounds = main.bounds
        return max(bounds.width, bounds.height)
    }
    
    static var minScreenLength:CGFloat {
        let bounds = main.bounds
        return min(bounds.width, bounds.height)
    }
    
    static var heightClass : HeightClass {
        switch maxScreenLength {
        case 668...CGFloat.greatestFiniteMagnitude:
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
        case 376...CGFloat.greatestFiniteMagnitude:
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
            for row in 0 ..< numberOfRows(inSection: section) {
                let indexPath = IndexPath(row: row, section: section)
                selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        }
    }
    
    func deselectAll() {
        indexPathsForSelectedRows?.forEach() {
            deselectRow(at: $0, animated: false)
        }
    }
    
    func selectOrDeselectAll() {
        guard (isEditing && allowsMultipleSelectionDuringEditing) || allowsMultipleSelection else { return }
        
        if indexPathsForSelectedRows != nil {
            deselectAll()
        } else {
            selectAll()
        }
    }
    
}

extension UIBarButtonItem {
    
    static func flexibleSpace() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }
    
}

extension UINavigationBar {
	
	func clearBackgroundImage() {
		let image = UIImage()
		setBackgroundImage(image, for: .default)
		shadowImage = image
	}
}

extension UIWindow {
    
    var visibleViewController: UIViewController? {
        return UIWindow.visibleViewController(from: rootViewController)
    }
    
    static func visibleViewController(from vc: UIViewController?) -> UIViewController? {
        if let nc = vc as? UINavigationController {
            return UIWindow.visibleViewController(from: nc.visibleViewController)
        } else if let tc = vc as? UITabBarController {
            return UIWindow.visibleViewController(from: tc.selectedViewController)
        } else if let pvc = vc?.presentedViewController {
            return UIWindow.visibleViewController(from: pvc)
        }
        return vc
    }
    
    
}

