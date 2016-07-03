//
//  ShortNotificationManager.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/22/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class ShortNotificationManager {

	
	static let instance = ShortNotificationManager()
	
	private static let fadeInAnimation = KyoozUtils.fadeInAnimationWithDuration(0.4)
	
	private lazy var presentationController:UIViewController = ContainerViewController.instance
	
	private weak var shortNotificationVC:ShortNotificationViewController?
	
	
    func presentShortNotification(withMessage message:String) {
        KyoozUtils.doInMainQueue() {
            self.presentShortNotification(message)
        }
    }
    
    private func presentShortNotification(message:String) {
        guard UIApplication.sharedApplication().applicationState == .Active else { return }
        
        if shortNotificationVC?.transitionOut() != nil {
            shortNotificationVC = nil
        }
        
        let vc = ShortNotificationViewController()
        
        vc.message = message
        let frameSize:CGSize = vc.estimatedSize
        
        let origin = CGPoint(x: (presentationController.view.frame.width - frameSize.width)/2, y: (presentationController.view.frame.height * 0.90) - frameSize.height)
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
