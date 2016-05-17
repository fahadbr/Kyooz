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
    private static let fulfilledColor = UIColor(colorLiteralRed: 0, green: 0.4, blue: 0, alpha: 1)
	
    let tutorialDTO:TutorialDTO
    
    private static let circleSize:CGFloat = 55
    private var startedTransitioningOut = false
    
    lazy var tutorialManager = TutorialManager.instance
    
    private lazy var instructionLabel:UILabel = {
        let label = UILabel()
        label.font = ThemeHelper.defaultFont
        label.numberOfLines = 0
        label.lineBreakMode = .ByWordWrapping
        label.textColor = ThemeHelper.defaultFontColor
        label.text = self.tutorialDTO.instructionText
        return label
    }()
	
	private lazy var stackView:UIView = {
		let cancelButton = CrossButtonView()
		cancelButton.addTarget(self, action: #selector(self.dismissTutorial), forControlEvents: .TouchUpInside)
		cancelButton.translatesAutoresizingMaskIntoConstraints = false
		cancelButton.heightAnchor.constraintEqualToConstant(45).active = true
		cancelButton.widthAnchor.constraintEqualToAnchor(cancelButton.heightAnchor).active = true
		
		let stackView = UIStackView(arrangedSubviews: [self.instructionLabel, cancelButton])
		stackView.axis = .Horizontal
		stackView.alignment = .Center
		return stackView
	}()
	
	private lazy var instructionView = UIView()
    
    lazy var circleLayer:CAShapeLayer = self.createCircleLayer()
    
	
    init(tutorialDTO:TutorialDTO) {
		self.tutorialDTO = tutorialDTO
		super.init(nibName: nil, bundle: nil)
		
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
    
    deinit {
        Logger.debug("deinit tutorial vc")
    }
	
	func createCircleLayer() -> CAShapeLayer {
		let size = self.dynamicType.circleSize
		let layer = CAShapeLayer()
		let path = UIBezierPath(ovalInRect: CGRect(x: 0, y: 0, width: size, height: size))
		layer.path = path.CGPath
		layer.strokeColor = ThemeHelper.defaultFontColor.CGColor
		layer.fillColor = UIColor.clearColor().CGColor
		layer.lineWidth = 2
		layer.frame = CGRect(x: self.view.bounds.midX - size/2, y: self.view.bounds.midY + size/2, width: size, height: size)
		return layer
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
        
        let slideDownAnimation = CABasicAnimation(keyPath: "transform")
        slideDownAnimation.duration = 0.5
        slideDownAnimation.fromValue = NSValue(CATransform3D: CATransform3DMakeTranslation(0, -ThemeHelper.plainHeaderHight, 0))
        slideDownAnimation.fillMode = kCAFillModeBackwards
        slideDownAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        instructionView.layer.addAnimation(slideDownAnimation, forKey: nil)
	}
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(self.removeAnimations), name: UIApplicationDidEnterBackgroundNotification, object: UIApplication.sharedApplication())
        notificationCenter.addObserver(self, selector: #selector(self.applyAnimation), name: UIApplicationDidBecomeActiveNotification, object: UIApplication.sharedApplication())
        
        applyAnimation()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        removeAnimations()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    func transitionOut(action:TutorialAction) {
        guard !startedTransitioningOut else { return }
        startedTransitioningOut = true
        
        removeAnimations()
        
        switch action {
        case .Fulfill:
            doFulfillAnimation()
        case .DismissFulfilled:
            doSlideUpAnimation()
        case .DismissUnfulfilled:
            doFadeOutAnimation()
        }
    }
	
	func dismissTutorial() {
		tutorialManager.dismissTutorial(tutorialDTO.tutorial, action: .DismissFulfilled)
	}
    
    private func doFulfillAnimation() {
        instructionLabel.text = "Great!"
        UIView.animateWithDuration(0.5, animations: {
            self.instructionView.backgroundColor = self.dynamicType.fulfilledColor
        }, completion: { _ in
            KyoozUtils.doInMainQueueAfterDelay(0.5) {
                self.doSlideUpAnimation()
            }
        })

    }
    
    func removeAnimations() {
		circleLayer.removeAllAnimations()
		circleLayer.removeFromSuperlayer()
    }
	
    func applyAnimation() {
		circleLayer.removeAllAnimations()
		if circleLayer.superlayer == nil {
			view.layer.addSublayer(circleLayer)
		}
    }
    
    private func doFadeOutAnimation() {
        let fadeOutAnimation = KyoozUtils.fadeOutAnimationWithDuration(0.2)
        fadeOutAnimation.delegate = self
        view.layer.addAnimation(fadeOutAnimation, forKey: nil)
    }
    
    private func doSlideUpAnimation() {
        let slideUpAnimation = CABasicAnimation(keyPath: "transform")
        slideUpAnimation.duration = 0.2
        slideUpAnimation.toValue = NSValue(CATransform3D: CATransform3DMakeTranslation(0, -ThemeHelper.plainHeaderHight, 0))
        slideUpAnimation.fillMode = kCAFillModeForwards
        slideUpAnimation.removedOnCompletion = false
        slideUpAnimation.delegate = self
        instructionView.layer.addAnimation(slideUpAnimation, forKey: nil)
    }
	
	override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        view.layer.removeAllAnimations()
        instructionView.layer.removeAllAnimations()
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
