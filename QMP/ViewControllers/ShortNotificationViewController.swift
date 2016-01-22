//
//  ShortNotificationViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/19/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class ShortNotificationViewController : UIViewController {
    
    @IBOutlet var undoButton:UIButton!
    @IBOutlet var messageLabel:UILabel!
    
	var message:String! {
		didSet {
			updateViews()
		}
	}
	
    var undoBlock:(() -> Void)? {
        didSet {
            updateViews()
        }
    }
    
    private var startedTransitioningOut = false
	
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.alpha = 0.9
        view.layer.cornerRadius = 10
		messageLabel.textColor = UIColor.blackColor()
		
        updateViews()
		
		//fade away after 5 seconds
		dispatch_after(KyoozUtils.getDispatchTimeForSeconds(4), dispatch_get_main_queue()) { [weak self] in
			self?.transitionOut()
		}
    }
    
    private func updateViews() {
        let hideUndoButton = undoBlock == nil
        undoButton?.hidden = hideUndoButton
		messageLabel?.text = message
        view?.userInteractionEnabled = !hideUndoButton
    }
    
    
    @IBAction func undoButtonPressed(sender: UIButton) {
		Logger.debug("undo button pressed")
        undoBlock?()
		transitionOut()
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
