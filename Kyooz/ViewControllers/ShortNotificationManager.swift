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
	
	private static let fadeInAnimation = KyoozUtils.fadeInAnimationWithDuration(0.5)
	
	private lazy var presentationController:UIViewController = ContainerViewController.instance
	
	private weak var shortNotificationVC:ShortNotificationViewController?
	
	
    func presentShortNotificationWithMessage(message:String) {
		guard UIApplication.sharedApplication().applicationState == .Active else { return }
		
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
		vc.view.layer.addAnimation(self.dynamicType.fadeInAnimation, forKey: nil)
	}
	
}
