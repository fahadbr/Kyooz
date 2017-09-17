//
//  TutorialViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/12/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class TutorialViewController : UIViewController, CAAnimationDelegate {
	
	private static let unfulfilledColor = UIColor.blue
    private static let fulfilledColor = UIColor(red: 0, green: 0.4, blue: 0, alpha: 1)
    private static let headerHeight = ThemeHelper.plainHeaderHight + 20
    
    let tutorialDTO:TutorialDTO
    
    private static let circleSize:CGFloat = 55
	private var dismissalAction:TutorialAction?
	
    lazy var tutorialManager = TutorialManager.instance
    
    private lazy var instructionLabel:UILabel = {
        let label = UILabel()
        label.font = ThemeHelper.defaultFont
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = ThemeHelper.defaultFontColor
        label.text = self.tutorialDTO.instructionText
        return label
    }()
	
	private lazy var stackView:UIView = {
		let cancelButton = CrossButtonView()
		cancelButton.addTarget(self, action: #selector(self.dismissTutorial), for: .touchUpInside)
		cancelButton.translatesAutoresizingMaskIntoConstraints = false
		cancelButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
		cancelButton.widthAnchor.constraint(equalTo: cancelButton.heightAnchor).isActive = true
		
		let stackView = UIStackView(arrangedSubviews: [self.instructionLabel, cancelButton])
		stackView.axis = .horizontal
		stackView.alignment = .center
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
		let size = type(of: self).circleSize
		let layer = CAShapeLayer()
		let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size))
		layer.path = path.cgPath
		layer.strokeColor = ThemeHelper.defaultFontColor.cgColor
		layer.fillColor = UIColor.clear.cgColor
		layer.lineWidth = 2
		layer.frame = CGRect(x: self.view.bounds.midX - size/2, y: self.view.bounds.midY + size/2, width: size, height: size)
		return layer
	}
	
	override func loadView() {
		self.view = OverlayView()
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = UIColor.clear

		ConstraintUtils.applyConstraintsToView(withAnchors: [.top, .left, .right], subView: instructionView, parentView: view)
		instructionView.heightAnchor.constraint(equalToConstant: TutorialViewController.headerHeight).isActive = true
		
		instructionView.backgroundColor = type(of: self).unfulfilledColor
		ConstraintUtils.applyConstraintsToView(withAnchors: [.centerX, .bottom], subView: stackView, parentView: instructionView)
		stackView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
		stackView.widthAnchor.constraint(equalTo: instructionView.widthAnchor, multiplier: 0.9).isActive = true
        
        let slideDownAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        slideDownAnimation.duration = 0.5
        slideDownAnimation.fromValue = -TutorialViewController.headerHeight
        slideDownAnimation.fillMode = kCAFillModeBackwards
        slideDownAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        instructionView.layer.add(slideDownAnimation, forKey: nil)
	}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(self.removeAnimations), name: NSNotification.Name.UIApplicationDidEnterBackground, object: UIApplication.shared)
        notificationCenter.addObserver(self, selector: #selector(self.applyAnimation), name: NSNotification.Name.UIApplicationDidBecomeActive, object: UIApplication.shared)
        
        applyAnimation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeAnimations()
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func transitionOut(_ action:TutorialAction) {
        guard dismissalAction == nil else { return }
        dismissalAction = action
        
        removeAnimations()
        
        switch action {
        case .fulfill where tutorialDTO.nextTutorial != nil:
            doFadeOutAnimation()
        case .fulfill:
            doFulfillAnimation()
        case .dismissFulfilled:
            doSlideUpAnimation()
        case .dismissUnfulfilled:
            doFadeOutAnimation()
        }
    }
	
    @objc func dismissTutorial() {
		tutorialManager.dismissTutorial(tutorialDTO.tutorial, action: .dismissFulfilled)
	}
    
    private func doFulfillAnimation() {
        instructionLabel.text = "Great!"
        UIView.animate(withDuration: 0.5, animations: {
            self.instructionView.backgroundColor = type(of: self).fulfilledColor
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
        view.layer.add(fadeOutAnimation, forKey: nil)
    }
    
    private func doSlideUpAnimation() {
        let slideUpAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        slideUpAnimation.duration = 0.2
        slideUpAnimation.toValue = -TutorialViewController.headerHeight
        slideUpAnimation.fillMode = kCAFillModeForwards
        slideUpAnimation.isRemovedOnCompletion = false
        slideUpAnimation.delegate = self
        instructionView.layer.add(slideUpAnimation, forKey: nil)
    }
	
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        view.layer.removeAllAnimations()
        instructionView.layer.removeAllAnimations()
		view.removeFromSuperview()
		removeFromParentViewController()
        if let nextTutorial = tutorialDTO.nextTutorial, let action = dismissalAction, action == .fulfill {
            tutorialManager.presentTutorialIfUnfulfilled(nextTutorial)
        }
	}
	
}

class OverlayView : UIView {
	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		let view = super.hitTest(point, with: event)
		if view == self {
			return nil
		}
		return view
	}
}

class NoAnimationTutorialViewController : TutorialViewController {
    override func applyAnimation() {
        //noop
    }
}
