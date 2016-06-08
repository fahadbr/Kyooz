//
//  HeaderViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/2/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit


let buttonHeight:CGFloat = 40
class HeaderViewController : UIViewController {
	
	private static let fixedHeight:CGFloat = 100
	
    var defaultHeight:CGFloat { return HeaderViewController.fixedHeight }
    var minimumHeight:CGFloat { return HeaderViewController.fixedHeight }
	var stackViewHeight:CGFloat { return buttonHeight }
    
    lazy var audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    private (set) lazy var leftButton:UIButton = self.createLeftButton()
	private (set) lazy var selectButton:MultiSelectButtonView = self.createSelectButton()
	
	
    //MARK: - FUNCTIONS
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		
        leftButton.alpha = ThemeHelper.defaultButtonTextAlpha
        selectButton.alpha = ThemeHelper.defaultButtonTextAlpha
        selectButton.scale = 0.5
		
		let stackView = UIStackView(arrangedSubviews: [leftButton, createCenterView(), selectButton])
		stackView.axis = .Horizontal
		stackView.distribution = .EqualCentering
		ConstraintUtils.applyConstraintsToView(withAnchors: [.CenterX, .Bottom], subView: stackView, parentView: view)
		stackView.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.9).active = true
		stackView.heightAnchor.constraintEqualToConstant(stackViewHeight).active = true
    }
	
	func setUpBackgroundViews() {
		view.backgroundColor = UIColor.clearColor()
		
		let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
		ConstraintUtils.applyStandardConstraintsToView(subView: blurView, parentView: view)
		view.sendSubviewToBack(blurView)
		
		accentLayer.strokeColor = ThemeHelper.defaultVividColor.CGColor
		accentLayer.lineWidth = 0.75
		view.layer.addSublayer(accentLayer)
	}
	
	func createLeftButton() -> UIButton {
		let leftButton = ShuffleButtonView()
		leftButton.heightAnchor.constraintEqualToConstant(buttonHeight).active = true
		leftButton.widthAnchor.constraintEqualToAnchor(leftButton.heightAnchor).active = true
		return leftButton
	}
	
	func createSelectButton() -> MultiSelectButtonView {
		let selectButton = MultiSelectButtonView()
		selectButton.heightAnchor.constraintEqualToConstant(buttonHeight).active = true
		selectButton.widthAnchor.constraintEqualToAnchor(selectButton.heightAnchor).active = true
		return selectButton
	}
	
	func createCenterView() -> UIView {
		return UIView()
	}
	
}
