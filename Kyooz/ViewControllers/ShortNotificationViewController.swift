//
//  ShortNotificationViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/19/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class ShortNotificationViewController : UIViewController, FadeOutViewController {
    
    private let maxWidth = UIScreen.main.bounds.width * 0.85
    private let maxHeight = UIScreen.main.bounds.height * 0.50
    
    private let messageLabel:UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.font = ThemeHelper.smallFontForStyle(.medium)
        label.textColor = ThemeHelper.defaultFontColor
        return label
    }()
    
    var animationDuration: Double {
        return 0.4
    }
    
	var message:String! {
		didSet {
			messageLabel.text = message
            messageLabel.bounds = messageLabel.textRect(forBounds: CGRect(x: 0, y: 0, width: maxWidth, height: maxHeight), limitedToNumberOfLines: 0)
		}
	}
    
    var estimatedSize:CGSize {
        let messageLabelSize = messageLabel.bounds.size
        let margin:CGFloat = 16
        return CGSize(width: messageLabelSize.width + margin, height: messageLabelSize.height + margin)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false
        let containerView = UIView()
        ConstraintUtils.applyStandardConstraintsToView(subView: containerView, parentView: view)
        ConstraintUtils.applyStandardConstraintsToView(subView: messageLabel, parentView: containerView)
        containerView.backgroundColor = ThemeHelper.defaultTableCellColor
        containerView.alpha = 0.9
        containerView.layer.cornerRadius = 10
        
        view.backgroundColor = UIColor.clear
        view.layer.shadowOpacity = 0.8
        view.layer.shadowOffset = CGSize.zero
        view.layer.shadowColor = UIColor.white.cgColor

		//fade away after 4 seconds
		DispatchQueue.main.asyncAfter(deadline: KyoozUtils.getDispatchTimeForSeconds(3)) { [weak self] in
			self?.transitionOut()
		}
    }

}
