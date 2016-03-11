//
//  FadeOutViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/10/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class FadeOutViewController: UIViewController {

    let fadeOutAnimation:CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 0.5
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.removedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        return animation
    }()
    
    
    private var startedTransitioningOut = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fadeOutAnimation.delegate = self
    }
    
    func transitionOut() {
        guard !startedTransitioningOut else { return }
        
        startedTransitioningOut = true
        
        view.layer.addAnimation(fadeOutAnimation, forKey: nil)
        
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        view.layer.removeAllAnimations()
        view.removeFromSuperview()
        removeFromParentViewController()
    }
}
