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
    var popGestureRecognizer:UIScreenEdgePanGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        popGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "handlePan:")
        popGestureRecognizer.edges = UIRectEdge.Left
        view.addGestureRecognizer(popGestureRecognizer)
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
