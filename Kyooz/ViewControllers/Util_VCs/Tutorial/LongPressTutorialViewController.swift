//
//  LongPressTutorialViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/16/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class LongPressTutorialViewController : TutorialViewController {
	
    var circleLayerAnimation:CAAnimation {
        return scaleAndFadeAnimation
    }
    
    var progressLayerAnimation:CAAnimation {
        return strokeAnimation
    }
    
    var keyTimes:[NSNumber] {
        return [0.0, 0.1, 0.8, 1.0]
    }
    
    var scale:CGFloat {
        return 1.2
    }
    
    var animationTime:Double {
        return 2
    }
    
    var delay:Double {
        return 2
    }
    
    lazy var progressLayer:CAShapeLayer = {
		let p = self.createCircleLayer()
		p.strokeColor = ThemeHelper.defaultVividColor.cgColor
		p.strokeEnd = 0
		p.frame.origin = CGPoint.zero
		self.circleLayer.addSublayer(p)
		return p
	}()
	
	private lazy var scaleAndFadeAnimation:CAAnimation = {
		
		let scaleAnimation = self.createKeyframeAnimation("transform.scale")
		scaleAnimation.values = [self.scale, 1, 1, 1]
		
		let opacityAnimation = self.createKeyframeAnimation("opacity")
		opacityAnimation.values = [0, 1, 1, 0]
		
		let fillAnimation = self.createKeyframeAnimation("fillColor")
		fillAnimation.values = [UIColor.clear.cgColor, ThemeHelper.defaultFontColor.cgColor, ThemeHelper.defaultFontColor.cgColor]
		fillAnimation.calculationMode = kCAAnimationDiscrete
		
		return self.wrapInAnimationGroup([scaleAnimation, opacityAnimation, fillAnimation])
	}()
	
	private lazy var strokeAnimation:CAAnimation = {
		let strokeEndAnimation = self.createKeyframeAnimation("strokeEnd")
		strokeEndAnimation.keyTimes = [0.0, 0.1, 0.6, 1.0]
		strokeEndAnimation.values = [0, 0, 1, 1]
		
		let fillAnimation = self.createKeyframeAnimation("fillColor")
		fillAnimation.keyTimes = [0.0, 0.1, 0.6, 1.0]
		fillAnimation.values = [UIColor.clear.cgColor, UIColor.clear.cgColor, ThemeHelper.defaultVividColor.cgColor]
		fillAnimation.calculationMode = kCAAnimationDiscrete
		return self.wrapInAnimationGroup([strokeEndAnimation, fillAnimation])
	}()
	
    

	
	override func applyAnimation() {
		super.applyAnimation()
		circleLayer.add(circleLayerAnimation, forKey: "tutorial")
		progressLayer.add(progressLayerAnimation, forKey: "progress")
	}
	
	override func removeAnimations() {
        progressLayer.removeAllAnimations()
        progressLayer.removeFromSuperlayer()
		super.removeAnimations()
	}
	
	func createKeyframeAnimation(_ keyPath:String) -> CAKeyframeAnimation {
		let animation = CAKeyframeAnimation(keyPath: keyPath)
		animation.keyTimes = keyTimes
		animation.duration = animationTime
		animation.fillMode = kCAFillModeBoth
		animation.beginTime = delay/2
		return animation
	}
	
    func wrapInAnimationGroup(_ animations:[CAAnimation]) -> CAAnimationGroup {
		let groupAnimation = CAAnimationGroup()
		groupAnimation.duration = delay + animationTime
		groupAnimation.repeatCount = Float.infinity
		groupAnimation.animations = animations
		return groupAnimation
	}
	
	
}

