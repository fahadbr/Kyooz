//
//  ShortNotificationViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/19/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class ShortNotificationViewController : FadeOutViewController {
    
    @IBOutlet var messageLabel:UILabel!
    
	var message:String! {
		didSet {
			messageLabel?.text = message
		}
	}
    
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

}
