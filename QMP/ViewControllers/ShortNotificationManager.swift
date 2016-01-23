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
	
	private let presentationController:UIViewController = ContainerViewController.instance
	private weak var shortNotificationVC:ShortNotificationViewController?
	
	func presentShortNotificationWithMessage(message:String) {
		let vc = UIStoryboard.shortNotificationViewController()
		
		vc.message = message
		
		let size = CGSize(width: presentationController.view.frame.width * 0.85, height: 60)
		let origin = CGPoint(x: (presentationController.view.frame.width - size.width)/2, y: presentationController.view.frame.height * 0.80)
		vc.view.frame = CGRect(origin: origin, size: size)
		self.shortNotificationVC = vc
		UIView.transitionWithView(presentationController.view, duration: 0.5, options: .TransitionCrossDissolve, animations: { () -> Void in
			self.presentationController.view.addSubview(vc.view)
			}) {[presentationController = self.presentationController]_ -> Void in
				presentationController.addChildViewController(vc)
				vc.didMoveToParentViewController(presentationController)
		}
	}
	
}
