//
//  TutorialViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/12/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class TutorialViewController : UIViewController {
	
	private static let unfulfilledColor = UIColor.blueColor()
	
	private let text:String
	private let tutorial:Tutorial
	
	private lazy var stackView:UIView = {
		let cancelButton = CrossButtonView()
		cancelButton.addTarget(self, action: #selector(self.dismissTutorial), forControlEvents: .TouchUpInside)
		cancelButton.translatesAutoresizingMaskIntoConstraints = false
		cancelButton.heightAnchor.constraintEqualToConstant(45).active = true
		cancelButton.widthAnchor.constraintEqualToAnchor(cancelButton.heightAnchor).active = true
		
		let instructionLabel = UILabel()
		instructionLabel.font = ThemeHelper.defaultFont
		instructionLabel.numberOfLines = 0
		instructionLabel.lineBreakMode = .ByWordWrapping
		instructionLabel.textColor = ThemeHelper.defaultFontColor
		instructionLabel.text = self.text
		
		let stackView = UIStackView(arrangedSubviews: [instructionLabel, cancelButton])
		stackView.axis = .Horizontal
		stackView.alignment = .Center
		return stackView
	}()
	
	private lazy var instructionView = UIView()
	
	init(text:String, forTutorial tutorial:Tutorial) {
		self.text = text
		self.tutorial = tutorial
		super.init(nibName: nil, bundle: nil)
		
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func loadView() {
		self.view = OverlayView()
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = UIColor.clearColor()

		ConstraintUtils.applyConstraintsToView(withAnchors: [.Top, .Left, .Right], subView: instructionView, parentView: view)
		instructionView.heightAnchor.constraintEqualToConstant(ThemeHelper.plainHeaderHight).active = true
		
		instructionView.backgroundColor = self.dynamicType.unfulfilledColor
		ConstraintUtils.applyConstraintsToView(withAnchors: [.CenterX, .Bottom], subView: stackView, parentView: instructionView)
		stackView.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor).active = true
		stackView.widthAnchor.constraintEqualToAnchor(instructionView.widthAnchor, multiplier: 0.9).active = true
		
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		let slideDownAnimation = CABasicAnimation(keyPath: "position")
		slideDownAnimation.duration = 0.5
		slideDownAnimation.fromValue = NSValue(CGPoint: CGPoint(x:instructionView.layer.position.x, y: instructionView.layer.position.y - ThemeHelper.plainHeaderHight))
		slideDownAnimation.fillMode = kCAFillModeBackwards
		slideDownAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
		instructionView.layer.addAnimation(slideDownAnimation, forKey: nil)
	}
	
	func dismissTutorial() {
		
		let slideUpAnimation = CABasicAnimation(keyPath: "position")
		slideUpAnimation.duration = 0.25
		slideUpAnimation.toValue = NSValue(CGPoint: CGPoint(x:instructionView.layer.position.x, y: instructionView.layer.position.y - ThemeHelper.plainHeaderHight))
		slideUpAnimation.fillMode = kCAFillModeForwards
		slideUpAnimation.removedOnCompletion = false
		slideUpAnimation.delegate = self
		instructionView.layer.addAnimation(slideUpAnimation, forKey: nil)
	}
	
	override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
		view.removeFromSuperview()
		removeFromParentViewController()
	}
	
}

class OverlayView : UIView {
	override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
		let view = super.hitTest(point, withEvent: event)
		if view == self {
			return nil
		}
		return view
	}
}
