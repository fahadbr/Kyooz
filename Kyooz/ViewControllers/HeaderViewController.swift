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
        centerViewController = UIViewController()
        super.init(coder: aDecoder)
    }
    
    //MARK: - FUNCTIONS
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		leftButton.heightAnchor.constraintEqualToConstant(buttonHeight).active = true
		leftButton.widthAnchor.constraintEqualToAnchor(leftButton.heightAnchor).active = true
		selectButton.heightAnchor.constraintEqualToConstant(buttonHeight).active = true
		selectButton.widthAnchor.constraintEqualToAnchor(selectButton.heightAnchor).active = true
		
        leftButton.alpha = ThemeHelper.defaultButtonTextAlpha
        selectButton.alpha = ThemeHelper.defaultButtonTextAlpha
        selectButton.scale = 0.5
		
		let stackView = UIStackView(arrangedSubviews: [leftButton, centerViewController.view, selectButton])
		stackView.axis = .Horizontal
        
        let constraints = ConstraintUtils.applyConstraintsToView(withAnchors: [.CenterX, .Bottom], subView: stackView, parentView: view)
        stackView.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.9).active = true
        
        switch centerViewController.dynamicType {
        case is HeaderLabelStackController.Type:
            stackView.distribution = .Fill
            stackView.alignment = UIStackViewAlignment.Bottom
            constraints[.Bottom]!.constant = -4
        case is SubGroupButtonController.Type:
            stackView.distribution = .Fill
		case is GenericWrapperViewController<UIToolbar>.Type:
			stackView.distribution = .Fill
        default:
            stackView.distribution = .EqualCentering
        }
    }
	
	func createLeftButton() -> UIButton {
		return ShuffleButtonView()
	}
	
	func createSelectButton() -> MultiSelectButtonView {
		return MultiSelectButtonView()
	}
	
}
