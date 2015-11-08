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
    static let defaultFontNameBold = defaultFontName + "-Medium"
    static let defaultFontSize = CGFloat(15.0)
    
    static let defaultFont = UIFont(name: defaultFontName + "-Medium", size: defaultFontSize)
    
    static let defaultTintColor = UIColor(white: 0.7, alpha: 1.0)
    
    static let defaultBarStyle = UIBarStyle.Black
    
    static let defaultTableCellColor = UIColor(white: 0.07, alpha: 1.0)
    
    static let defaultFontColor = UIColor.whiteColor()
    static let defaultVividColor = UIColor(red: 64.0/225.0, green: 224.0/225.0, blue: 208.0/225.0, alpha: 1.0)
    
    static let barsAreTranslucent = true
    
    static func applyGlobalAppearanceSettings() {
        var titleTextAttributes = [String : AnyObject]()
        titleTextAttributes[NSFontAttributeName] = UIFont(name:defaultFontName, size:CGFloat(18.0))
        
        UINavigationBar.appearance().titleTextAttributes = titleTextAttributes
        UINavigationBar.appearance().tintColor = defaultTintColor
        UINavigationBar.appearance().barStyle = defaultBarStyle
        UINavigationBar.appearance().translucent = barsAreTranslucent
        
        var uiBarButtonTextAttributes = [String : AnyObject]()
        uiBarButtonTextAttributes[NSFontAttributeName] = defaultFont
        UIBarButtonItem.appearance().setTitleTextAttributes(uiBarButtonTextAttributes, forState: UIControlState.Normal)
        UIBarButtonItem.appearance().setTitleTextAttributes(uiBarButtonTextAttributes, forState: UIControlState.Highlighted)
        UIBarButtonItem.appearance().tintColor = defaultTintColor
        
        UITableViewCell.appearance().backgroundColor = defaultTableCellColor
//        UITableViewCell.appearance().sel
        UITableView.appearance().backgroundColor = defaultTableCellColor
        UITableView.appearance().tintColor = defaultTintColor
        UITableView.appearance().sectionIndexBackgroundColor = defaultTableCellColor
        UITableView.appearance().sectionIndexTrackingBackgroundColor = defaultTableCellColor        
        
        UIToolbar.appearance().tintColor = defaultTintColor
        UIToolbar.appearance().barStyle = defaultBarStyle
        UIToolbar.appearance().translucent = barsAreTranslucent
        
        UILabel.appearance().textColor = defaultFontColor
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated:true)
    }
    
}
