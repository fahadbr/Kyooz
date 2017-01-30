//
//  ThemeHelper.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 4/3/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

struct ThemeHelper {
	
	enum FontStyle : Int { case normal, medium, bold
		var fontName:String {
			switch self {
			case .bold:
				return defaultFontNameBold
			case .medium:
				return defaultFontNameMedium
			case .normal:
				return defaultFontName
			}
		}
	}
    
    static let plainHeaderHight:CGFloat = 65
    
    static let defaultFontName = "Avenir"
    static let defaultFontNameMedium = defaultFontName + "-Medium"
    static let defaultFontNameBold = defaultFontName + "-Heavy"
	
    static var contentSizeRatio:CGFloat {
        return defaultFontSize/referenceFontSize
    }

    private static let referenceFontSize:CGFloat = 15
    private (set) static var defaultFontSize:CGFloat = {
        let sizeToUse:CGFloat
        
        Logger.debug("Setting content size category of \(UIApplication.shared.preferredContentSizeCategory)")
        switch UIApplication.shared.preferredContentSizeCategory {
//        case UIContentSizeCategoryExtraSmall:
//            sizeToUse = referenceFontSize - 2
//        case UIContentSizeCategorySmall:
//            sizeToUse = referenceFontSize - 1
//        case UIContentSizeCategoryMedium:
//            sizeToUse = referenceFontSize
        case UIContentSizeCategory.large:
            sizeToUse = referenceFontSize + 1
        case UIContentSizeCategory.extraLarge:
            sizeToUse = referenceFontSize + 2
        case UIContentSizeCategory.extraExtraLarge:
            sizeToUse = referenceFontSize + 3
        case UIContentSizeCategory.extraExtraExtraLarge,
             UIContentSizeCategory.accessibilityMedium,
             UIContentSizeCategory.accessibilityLarge,
             UIContentSizeCategory.accessibilityExtraLarge,
             UIContentSizeCategory.accessibilityExtraExtraLarge,
             UIContentSizeCategory.accessibilityExtraExtraExtraLarge:
            sizeToUse = referenceFontSize + 4
        default:
            sizeToUse = referenceFontSize
        }
        return sizeToUse
    }()
    
	static var smallFontSize:CGFloat {
		return defaultFontSize - 3
	}
    
    static let defaultFont = UIFont(name: defaultFontNameMedium, size: defaultFontSize)
    static let defaultButtonTextAlpha:CGFloat = 0.6
    static let defaultTintColor = UIColor(white: 0.7, alpha: 1.0)
	
    static let defaultBarStyle = UIBarStyle.black
    
    static let defaultTableCellColor = UIColor(white: 0.09, alpha: 1.0)
    static let sidePanelTableViewRowHeight:CGFloat = 48 * contentSizeRatio
    static let tableViewRowHeight:CGFloat = 60 * contentSizeRatio
    static let tableViewSectionHeaderHeight:CGFloat = 40 * contentSizeRatio
    
    static let defaultFontColor = UIColor.white
	
	static let defaultVividColor = UIColor(red: 219.0/255.0, green: 44/255.0, blue: 56/255.0, alpha: 1.0)

    static let barsAreTranslucent = true
	
	static func smallFontForStyle(_ style:FontStyle) -> UIFont? {
		return UIFont(name: style.fontName, size: smallFontSize)
	}
	
	static func defaultFont(forStyle style:FontStyle) -> UIFont? {
		return UIFont(name: style.fontName, size: defaultFontSize)
	}
    
    
    static func applyGlobalAppearanceSettings() {
        var titleTextAttributes = [String : AnyObject]()
        titleTextAttributes[NSFontAttributeName] = UIFont(name:defaultFontNameBold, size:defaultFontSize)
        
        UINavigationBar.appearance().titleTextAttributes = titleTextAttributes
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().barStyle = defaultBarStyle
        UINavigationBar.appearance().isTranslucent = barsAreTranslucent
        UINavigationBar.appearance().backgroundColor = UIColor.clear

        
        let font = UIFont(name:defaultFontName, size: UIScreen.widthClass == .iPhone345 ? smallFontSize - 2 : smallFontSize + 1)
        let uiBarButtonTextAttributes:[String:AnyObject] = [NSFontAttributeName:font ?? UIFont.systemFont(ofSize: smallFontSize)]
        UIBarButtonItem.appearance().setTitleTextAttributes(uiBarButtonTextAttributes, for: UIControlState())
        var highlightedAttributes = uiBarButtonTextAttributes
        highlightedAttributes[NSForegroundColorAttributeName] = ThemeHelper.defaultVividColor
        UIBarButtonItem.appearance().setTitleTextAttributes(highlightedAttributes, for: .highlighted)
        UIBarButtonItem.appearance().tintColor = defaultTintColor
        
        UITableViewCell.appearance().backgroundColor = defaultTableCellColor
		
        UITableView.appearance().backgroundColor = defaultTableCellColor
        UITableView.appearance().tintColor = defaultVividColor
        UITableView.appearance().sectionIndexBackgroundColor = defaultTableCellColor
        UITableView.appearance().sectionIndexTrackingBackgroundColor = defaultTableCellColor        
        UITableView.appearance().separatorColor = UIColor(white: 0.2, alpha: 1.0)
        UITableView.appearance().separatorStyle = .none
        
        UIToolbar.appearance().tintColor = defaultTintColor
        UIToolbar.appearance().barStyle = defaultBarStyle
        UIToolbar.appearance().isTranslucent = barsAreTranslucent
        
        UILabel.appearance().textColor = defaultFontColor
		
		UITextView.appearance().backgroundColor = defaultTableCellColor
    }
    
}
