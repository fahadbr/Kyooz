//
//  LongPressTutorialViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/16/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

private let animationTime:Double = 2
private let delay:Double = 2
private let times:[NSNumber] = [0.0, 0.1, 0.8, 1.0]
private let scale:CGFloat = 1.2

class LongPressTutorialViewController : TutorialViewController {
	
	private lazy var progressLayer:CAShapeLayer = {
		let p = self.createCircleLayer()
		p.strokeColor = ThemeHelper.defaultVividColor.CGColor
		p.strokeEnd = 0
		p.frame.origin = CGPoint.zero
		self.circleLayer.addSublayer(p)
		return p
	}()
	
	private lazy var longPressAnimation:CAAnimation = {
		
		let scaleAnimation = self.createKeyframeAnimation("transform.scale")
		scaleAnimation.values = [scale, 1, 1, 1]
		
		let opacityAnimation = self.createKeyframeAnimation("opacity")
		opacityAnimation.values = [0, 1, 1, 0]
		
		let fillAnimation = self.createKeyframeAnimation("fillColor")
		fillAnimation.values = [UIColor.clearColor().CGColor, ThemeHelper.defaultFontColor.CGColor, ThemeHelper.defaultFontColor.CGColor]
		fillAnimation.calculationMode = kCAAnimationDiscrete
		
		return self.wrapInAnimationGroup([scaleAnimation, opacityAnimation, fillAnimation])
	}()
	
	private lazy var strokeAnimation:CAAnimation = {
		let strokeEndAnimation = self.createKeyframeAnimation("strokeEnd")
		strokeEndAnimation.keyTimes = [0.0, 0.1, 0.7, 1.0]
		strokeEndAnimation.values = [0, 0, 1, 1]
		
		let fillAnimation = self.createKeyframeAnimation("fillColor")
		fillAnimation.keyTimes = [0.0, 0.1, 0.7, 1.0]
		fillAnimation.values = [UIColor.clearColor().CGColor, UIColor.clearColor().CGColor, ThemeHelper.defaultVividColor.CGColor]
		fillAnimation.calculationMode = kCAAnimationDiscrete
		return self.wrapInAnimationGroup([strokeEndAnimation, fillAnimation])
	}()
	
	
	
	override func applyAnimation() {
		super.applyAnimation()
		circleLayer.addAnimation(longPressAnimation, forKey: "tutorial")
		progressLayer.addAnimation(strokeAnimation, forKey: "progress")
	}
	
	override func removeAnimations() {
		super.removeAnimations()
		progressLayer.removeAllAnimations()
	}
	
	private func createKeyframeAnimation(keyPath:String) -> CAKeyframeAnimation {
		
		let animation = CAKeyframeAnimation(keyPath: keyPath)
		animation.keyTimes = times
		animation.duration = animationTime
		animation.fillMode = kCAFillModeBoth
		animation.beginTime = delay/2
		return animation
	}
	
	private func wrapInAnimationGroup(animations:[CAAnimation]) -> CAAnimationGroup {
		let groupAnimation = CAAnimationGroup()
		groupAnimation.duration = delay + animationTime
		groupAnimation.repeatCount = Float.infinity
		groupAnimation.animations = animations
		return groupAnimation
	}
	
	
}
