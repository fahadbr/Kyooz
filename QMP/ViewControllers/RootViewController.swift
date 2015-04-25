//
//  RootViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/15/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class RootViewController: UIViewController {
    
    var libraryNavigationController:UINavigationController!
    
    var nowPlayingSummaryNavigationController:UINavigationController!
    var nowPlayingSummaryViewController:NowPlayingSummaryViewController!
    
    @IBAction func unwindToBrowser(segue : UIStoryboardSegue)  {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.libraryNavigationController = UIStoryboard.libraryNavigationController()
        let originalFrame = self.libraryNavigationController.view.frame
        let newOrigin = originalFrame.origin
        let newSize = CGSize(width: CGRectGetWidth(originalFrame), height: originalFrame.height - 44)
        self.libraryNavigationController.view.frame = CGRect(origin: newOrigin, size: newSize)
        
        self.view.addSubview(libraryNavigationController.view)
        self.addChildViewController(libraryNavigationController)
        self.libraryNavigationController.didMoveToParentViewController(self)
        
//        self.nowPlayingSummaryViewController = UIStoryboard.nowPlayingSummaryViewController()
//        self.nowPlayingSummaryNavigationController = UINavigationController(rootViewController: self.nowPlayingSummaryViewController)
//        self.nowPlayingSummaryNavigationController.toolbarHidden = false
//        self.nowPlayingSummaryNavigationController.navigationBarHidden = true
        
        

    }

    func enableGesturesInSubViews(#shouldEnable:Bool) {
        self.libraryNavigationController.interactivePopGestureRecognizer.enabled = shouldEnable
    }
    

}
