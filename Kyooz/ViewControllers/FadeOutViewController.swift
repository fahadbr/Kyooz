//
//  FadeOutViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/10/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

protocol FadeOutViewController: class {
    
    var animationDuration: Double { get }
    
    func transitionOut()
}

extension FadeOutViewController where Self : UIViewController {
    
    func transitionOut() {
        CATransaction.begin()
        
        CATransaction.setCompletionBlock() {
            self.view.layer.removeAllAnimations()
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
        }
        
        view.layer.addAnimation(KyoozUtils.fadeOutAnimationWithDuration(animationDuration), forKey: nil)
        
        CATransaction.commit()
    }
    
}
