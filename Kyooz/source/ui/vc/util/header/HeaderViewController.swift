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
		
		leftButton.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
		leftButton.widthAnchor.constraint(equalTo: leftButton.heightAnchor).isActive = true
		selectButton.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
		selectButton.widthAnchor.constraint(equalTo: selectButton.heightAnchor).isActive = true
		
        leftButton.alpha = ThemeHelper.defaultButtonTextAlpha
        selectButton.alpha = ThemeHelper.defaultButtonTextAlpha
        selectButton.scale = 0.5
		
		let stackView = UIStackView(arrangedSubviews: [leftButton, centerViewController.view, selectButton])
		stackView.axis = .horizontal
        
        let constraints = ConstraintUtils.applyConstraintsToView(withAnchors: [.centerX, .bottom], subView: stackView, parentView: view)
        var multiplier:CGFloat = 0.9
        
        
        switch type(of: centerViewController) {
        case is HeaderLabelStackController.Type:
            stackView.distribution = .fill
            stackView.alignment = UIStackViewAlignment.bottom
            constraints[.bottom]!.constant = -4
        case is SubGroupButtonController.Type:
            stackView.distribution = .fill
		case is GenericWrapperViewController<UISearchBar>.Type:
			stackView.distribution = .fill
            multiplier = 1.0
        default:
            stackView.distribution = .equalCentering
        }
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: multiplier).isActive = true
    }
	
	func createLeftButton() -> UIButton {
		return ShuffleButtonView()
	}
	
	func createSelectButton() -> MultiSelectButtonView {
		return MultiSelectButtonView()
	}
	
}
