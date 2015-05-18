//
//  StoryboardExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/24/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

extension UIStoryboard {

    class func mainStoryboard() -> UIStoryboard {
        return UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
    }
    
    class func settingsStoryboard() -> UIStoryboard {
        return UIStoryboard(name: "Settings", bundle:NSBundle.mainBundle())
    }
    
    class func libraryNavigationController() -> UINavigationController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("libraryNavigationController") as! UINavigationController
    }
    
    class func nowPlayingViewController() -> NowPlayingViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("nowPlayingViewController") as! NowPlayingViewController
    }
    
    class func nowPlayingSummaryViewController() -> NowPlayingSummaryViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("nowPlayingSummaryViewController") as! NowPlayingSummaryViewController
    }
    
    class func settingsViewController() -> UINavigationController {
        return settingsStoryboard().instantiateInitialViewController() as! UINavigationController
    }
}
