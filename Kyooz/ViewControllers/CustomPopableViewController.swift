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
        popGestureRecognizer.edges = UIRectEdge.left
        return popGestureRecognizer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popGestureRecognizer.isEnabled = UserDefaults.standard.bool(forKey: UserDefaultKeys.ReduceAnimations)
        view.addGestureRecognizer(popGestureRecognizer)
        ContainerViewController.instance.centerPanelPanGestureRecognizer.require(toFail: popGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableCustomPopGestureRecognizer(UserDefaults.standard.bool(forKey: UserDefaultKeys.ReduceAnimations))
    }
    
    func enableCustomPopGestureRecognizer(_ shouldEnable:Bool) {
        popGestureRecognizer.isEnabled = shouldEnable
    }

    //MARK: - gesture recognizer handling methods
    final func handlePan(_ recognizer:UIPanGestureRecognizer) {
        if recognizer.state == .began {
            transitionAnimator.interactive = true
            navigationController?.popViewController(animated: true)
        }
        transitionAnimator.handlePan(recognizer)
    }


}
