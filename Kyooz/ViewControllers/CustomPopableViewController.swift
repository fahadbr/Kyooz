//
//  CustomPopableViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/9/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class CustomPopableViewController: UIViewController {

    var transitionAnimator = ViewControllerFadeAnimator.instance
    lazy var popGestureRecognizer:UIScreenEdgePanGestureRecognizer = {
        let popGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(CustomPopableViewController.handlePan(_:)))
        popGestureRecognizer.edges = UIRectEdge.Left
        return popGestureRecognizer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popGestureRecognizer.enabled = NSUserDefaults.standardUserDefaults().boolForKey(UserDefaultKeys.ReduceAnimations)
        view.addGestureRecognizer(popGestureRecognizer)
        ContainerViewController.instance.centerPanelPanGestureRecognizer.requireGestureRecognizerToFail(popGestureRecognizer)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        enableCustomPopGestureRecognizer(NSUserDefaults.standardUserDefaults().boolForKey(UserDefaultKeys.ReduceAnimations))
    }
    
    func enableCustomPopGestureRecognizer(shouldEnable:Bool) {
        popGestureRecognizer.enabled = shouldEnable
    }

    //MARK: - gesture recognizer handling methods
    final func handlePan(recognizer:UIPanGestureRecognizer) {
        if recognizer.state == .Began {
            transitionAnimator.interactive = true
            navigationController?.popViewControllerAnimated(true)
        }
        transitionAnimator.handlePan(recognizer)
    }


}
