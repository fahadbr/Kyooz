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
    
    lazy var audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    private (set) lazy var leftButton:UIButton = self.createLeftButton()
	private (set) lazy var selectButton:MultiSelectButtonView = self.createSelectButton()
	
	
    let centerViewController:UIViewController
    
    init(centerViewController:UIViewController) {
        self.centerViewController = centerViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - FUNCTIONS
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		
        leftButton.alpha = ThemeHelper.defaultButtonTextAlpha
        selectButton.alpha = ThemeHelper.defaultButtonTextAlpha
        selectButton.scale = 0.5
		
		let stackView = UIStackView(arrangedSubviews: [leftButton, centerViewController.view, selectButton])
		stackView.axis = .Horizontal
        
        let constraints = ConstraintUtils.applyConstraintsToView(withAnchors: [.CenterX, .Bottom], subView: stackView, parentView: view)
        stackView.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.9).active = true
        
        if centerViewController is SubGroupButtonController {
            stackView.distribution = .EqualCentering
        } else if centerViewController is HeaderLabelStackController {
            stackView.distribution = .Fill
            stackView.alignment = UIStackViewAlignment.Bottom
            constraints[.Bottom]!.constant = -4
        }
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
	
}
