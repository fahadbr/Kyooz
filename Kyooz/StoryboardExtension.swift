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

    static func mainStoryboard() -> UIStoryboard {
        struct Static {
            static let instance = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        }
        return Static.instance
    }
    
    static func settingsStoryboard() -> UIStoryboard {
        struct Static {
            static let instance = UIStoryboard(name: "Settings", bundle:NSBundle.mainBundle())
        }
        return Static.instance
    }

    
    static func warningViewController() -> WarningViewController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("warningViewController") as! WarningViewController
    }
    
    static func systemQueueResyncWorkflowController() -> SystemQueueResyncWorkflowController {
        return mainStoryboard().instantiateViewControllerWithIdentifier("systemQueueResyncWorkflowController") as! SystemQueueResyncWorkflowController
    }
    
    static func settingsViewController() -> UIViewController {
        return settingsStoryboard().instantiateInitialViewController()!
    }
    
    
}
