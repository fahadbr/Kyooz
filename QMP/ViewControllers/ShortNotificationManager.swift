//
//  ShortNotificationManager.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/22/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class ShortNotificationManager : NSObject {
    
    enum Size : Int { case Small, Large }
	
	static let instance = ShortNotificationManager()
	
	private let presentationController:UIViewController = ContainerViewController.instance
    
    private let fadeIntAnimation:CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 0.5
        animation.fromValue = 0.0
        animation.toValue = 1.0
        return animation
    }()
    
	private weak var shortNotificationVC:ShortNotificationViewController?
	
    func presentShortNotificationWithMessage(message:String, withSize size:Size) {
        if let previousVC = self.shortNotificationVC {
            previousVC.transitionOut()
        }
        
        
		let vc = UIStoryboard.shortNotificationViewController()
		
		vc.message = message
        let frameSize:CGSize
        switch size {
        case .Small:
            frameSize = CGSize(width: presentationController.view.frame.width * 0.60, height: 30)
        case .Large:
            frameSize = CGSize(width: presentationController.view.frame.width * 0.85, height: 60)
        }
        
		let origin = CGPoint(x: (presentationController.view.frame.width - frameSize.width)/2, y: presentationController.view.frame.height * 0.80)
		vc.view.frame = CGRect(origin: origin, size: frameSize)
		self.shortNotificationVC = vc
		UIView.transitionWithView(presentationController.view, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: { () -> Void in
			self.presentationController.view.addSubview(vc.view)
			}) {[presentationController = self.presentationController]_ -> Void in
				presentationController.addChildViewController(vc)
				vc.didMoveToParentViewController(presentationController)
		}
	}
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        
    }
	
}
