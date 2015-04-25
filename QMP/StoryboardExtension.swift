//
//  StoryboardExtension.swift
//  QMP
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
    
//    static let mainStoryboard:UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
    
    class func rootViewController() -> UIViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("rootViewController") as! UIViewController
    }
    
//    class func libraryViewController() -> UIViewController {
//        return mainStoryboard().instantiateViewControllerWithIdentifier("libraryViewController") as! UIViewController
//    }
    
    class func nowPlayingViewController() -> UIViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("nowPlayingViewController") as! UIViewController
    }
}
