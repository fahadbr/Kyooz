//
//  ShortNotificationManager.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/22/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class ShortNotificationManager {
	
	//TODO: get rid of this enum
    enum Size : Int { case Small, Large }
	
	static let instance = ShortNotificationManager()
	
	private let presentationController:UIViewController = ContainerViewController.instance
	private let fadeInAnimation:CABasicAnimation = {
		let animation = CABasicAnimation(keyPath: "opacity")
		animation.duration = 0.5
		animation.fromValue = 0.0
		animation.toValue = 1.0
		animation.fillMode = kCAFillModeBackwards
		return animation
	}()
		
	private weak var shortNotificationVC:ShortNotificationViewController?
	
	
    func presentShortNotificationWithMessage(message:String, withSize size:Size) {
        if let previousVC = self.shortNotificationVC {
            previousVC.transitionOut()
        }
        
        
		let vc = ShortNotificationViewController()
		
		vc.message = message
        let frameSize:CGSize = vc.estimatedSize
        
		let origin = CGPoint(x: (presentationController.view.frame.width - frameSize.width)/2, y: presentationController.view.frame.height * 0.80)
		vc.view.frame = CGRect(origin: origin, size: frameSize)
		self.shortNotificationVC = vc
		
		presentationController.view.addSubview(vc.view)
		presentationController.addChildViewController(vc)
		vc.didMoveToParentViewController(presentationController)
		
		vc.view.layer.rasterizationScale = UIScreen.mainScreen().scale
		vc.view.layer.shouldRasterize = true
		vc.view.layer.addAnimation(fadeInAnimation, forKey: nil)
	}
	
}
