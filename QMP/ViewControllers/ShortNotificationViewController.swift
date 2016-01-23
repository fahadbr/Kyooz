//
//  ShortNotificationViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/19/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class ShortNotificationViewController : UIViewController {
	
    private let fadeOutAnimation:CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 0.5
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.removedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        return animation
    }()
    
    @IBOutlet var messageLabel:UILabel!
    
	var message:String! {
		didSet {
			messageLabel?.text = message
		}
	}
    
    private var startedTransitioningOut = false
	
//    deinit {
//        Logger.debug("deinit of short notification with message \(message)")
//    }
	
    override func viewDidLoad() {
        super.viewDidLoad()
        view.alpha = 0.9
        view.layer.cornerRadius = 10
		messageLabel.textColor = UIColor.blackColor()
		messageLabel.text = message
		fadeOutAnimation.delegate = self

		//fade away after 4 seconds
		dispatch_after(KyoozUtils.getDispatchTimeForSeconds(4), dispatch_get_main_queue()) { [weak self] in
			self?.transitionOut()
		}
    }
	
    func transitionOut() {
        if startedTransitioningOut { return }
        
        startedTransitioningOut = true
        
        view.layer.addAnimation(fadeOutAnimation, forKey: nil)
        
	}
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        view.layer.removeAllAnimations()
        view.removeFromSuperview()
        removeFromParentViewController()
    }
    
}
