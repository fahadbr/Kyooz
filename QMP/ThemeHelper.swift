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
    
    static let defaultFontName = "Avenir"
    static let defaultFontNameMedium = defaultFontName + "-Medium"
    static let defaultFontNameBold = defaultFontName + "-Heavy"
	static let defaultFontSize:CGFloat = 15.0
    
    static let defaultFont = UIFont(name: defaultFontNameMedium, size: defaultFontSize)
    static let defaultButtonTextAlpha:CGFloat = 0.6
    static let defaultTintColor = UIColor(white: 0.7, alpha: 1.0)
    
    static let defaultBarStyle = UIBarStyle.Black
    
    static let defaultTableCellColor = UIColor(white: 0.09, alpha: 1.0)
    
    static let defaultFontColor = UIColor.whiteColor()
	
//    static let defaultVividColor = UIColor(red: 64.0/255.0, green: 224.0/255.0, blue: 208.0/255.0, alpha: 1.0)
    static let defaultVividColor = UIColor(red: 255.0/255.0, green: 93/255.0, blue: 53/255.0, alpha: 1.0)
//    static let darkAccentColor = UIColor(red: 57.0/255.0, green: 0/255.0, blue: 8.0/255.0, alpha: 1.0)
	static let darkAccentColor = UIColor(red: 75.0/255.0, green: 0/255.0, blue: 11.0/255.0, alpha: 1.0)
	
    static let barsAreTranslucent = true
    
    static let tableViewSectionHeaderHeight:CGFloat = 40
    
    static func applyGlobalAppearanceSettings() {
        var titleTextAttributes = [String : AnyObject]()
        titleTextAttributes[NSFontAttributeName] = UIFont(name:defaultFontNameBold, size:defaultFontSize)
        
        UINavigationBar.appearance().titleTextAttributes = titleTextAttributes
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().barStyle = defaultBarStyle
        UINavigationBar.appearance().translucent = barsAreTranslucent
        
        var uiBarButtonTextAttributes = [String : AnyObject]()
        uiBarButtonTextAttributes[NSFontAttributeName] = defaultFont
        UIBarButtonItem.appearance().setTitleTextAttributes(uiBarButtonTextAttributes, forState: UIControlState.Normal)
        UIBarButtonItem.appearance().setTitleTextAttributes(uiBarButtonTextAttributes, forState: UIControlState.Highlighted)
        UIBarButtonItem.appearance().tintColor = defaultTintColor
        
        UITableViewCell.appearance().backgroundColor = defaultTableCellColor
        
        UITableView.appearance().backgroundColor = defaultTableCellColor
        UITableView.appearance().tintColor = defaultTintColor
        UITableView.appearance().sectionIndexBackgroundColor = defaultTableCellColor
        UITableView.appearance().sectionIndexTrackingBackgroundColor = defaultTableCellColor        
        UITableView.appearance().separatorColor = UIColor(white: 0.2, alpha: 1.0)
        
        UIToolbar.appearance().tintColor = defaultTintColor
        UIToolbar.appearance().barStyle = defaultBarStyle
        UIToolbar.appearance().translucent = barsAreTranslucent
        
        UILabel.appearance().textColor = defaultFontColor
    }
    
}
