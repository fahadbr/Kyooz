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
    static let defaultFontNameBold = defaultFontName + "-Black"
    static let defaultFontSize = CGFloat(14.0)
    
    static let defaultFont = UIFont(name: defaultFontName, size: defaultFontSize)
    
    
    static func applyGlobalAppearanceSettings() {
        var titleTextAttributes = [NSObject : AnyObject]()
        titleTextAttributes[NSFontAttributeName] = UIFont(name:defaultFontName, size:CGFloat(18.0))
        
        UINavigationBar.appearance().titleTextAttributes = titleTextAttributes
        UINavigationBar.appearance().tintColor = UIColor.blackColor()
        
        var uiBarButtonTextAttributes = [NSObject : AnyObject]()
        uiBarButtonTextAttributes[NSFontAttributeName] = defaultFont
        UIBarButtonItem.appearance().setTitleTextAttributes(uiBarButtonTextAttributes, forState: UIControlState.Normal)
        UIBarButtonItem.appearance().setTitleTextAttributes(uiBarButtonTextAttributes, forState: UIControlState.Highlighted)
        
        UITableView.appearance().tintColor = UIColor.blackColor()
        
        UIToolbar.appearance().tintColor = UIColor.blackColor()
    }
    
}
