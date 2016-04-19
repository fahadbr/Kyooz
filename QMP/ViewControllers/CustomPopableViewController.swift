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
