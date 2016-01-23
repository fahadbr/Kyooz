//
//  ShortNotificationViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/19/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class ShortNotificationViewController : UIViewController {
	
    @IBOutlet var messageLabel:UILabel!
    
	var message:String! {
		didSet {
			messageLabel?.text = message
		}
	}
    
    private var startedTransitioningOut = false
	
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.alpha = 0.9
        view.layer.cornerRadius = 10
		messageLabel.textColor = UIColor.blackColor()
		messageLabel.text = message
		
		//fade away after 4 seconds
		dispatch_after(KyoozUtils.getDispatchTimeForSeconds(4), dispatch_get_main_queue()) { [weak self] in
			self?.transitionOut()
		}
    }
	
    func transitionOut() {
		guard let superView = view.superview else {
			return
		}
        if startedTransitioningOut { return }
        
        startedTransitioningOut = true
        
		UIView.transitionWithView(superView, duration: 0.5, options: .TransitionCrossDissolve, animations: { () -> Void in
			self.view.removeFromSuperview()
			self.removeFromParentViewController()
			}, completion: nil)
	}
    
}
