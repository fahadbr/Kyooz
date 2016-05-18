//
//  DragToRearrangeTutorialViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/17/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit


class DragToRearrangeTutorialViewController : LongPressTutorialViewController {
    
    override var circleLayerAnimation: CAAnimation {
        return scaleAndFadeAnimation
    }
    
    override var progressLayerAnimation: CAAnimation {
        return strokeAnimation
    }
    
    override var animationTime: Double {
        return 2.5
    }
    
    override var delay: Double {
        return 2.5
    }
    
    override var keyTimes: [NSNumber] {
        return [0.0, 0.05, 0.5, 0.9, 1.0]
    }
    
    private lazy var scaleAndFadeAnimation:CAAnimation = {
        
        let scaleAnimation = self.createKeyframeAnimation("transform.scale")
        scaleAnimation.values = [self.scale, 1, 1, 1, self.scale]
        
        let opacityAnimation = self.createKeyframeAnimation("opacity")
        opacityAnimation.values = [0, 1, 1, 1, 0]
        
        let offsetY = self.view.frame.height * 0.15
        let defaultTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        let easeOutTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        let translateAnimation = self.createKeyframeAnimation("transform.translation.y")
        translateAnimation.values = [-offsetY, -offsetY, -offsetY, offsetY, offsetY]
        translateAnimation.timingFunctions = [defaultTimingFunction, defaultTimingFunction, easeOutTimingFunction, easeOutTimingFunction, defaultTimingFunction]
        
        let fillAnimation = self.createKeyframeAnimation("fillColor")
        fillAnimation.values = [UIColor.clearColor().CGColor, ThemeHelper.defaultFontColor.CGColor, ThemeHelper.defaultFontColor.CGColor, ThemeHelper.defaultFontColor.CGColor]
        fillAnimation.calculationMode = kCAAnimationDiscrete
        
        return self.wrapInAnimationGroup([scaleAnimation, opacityAnimation, translateAnimation, fillAnimation])
    }()
    
    private lazy var strokeAnimation:CAAnimation = {
        let strokeEndAnimation = self.createKeyframeAnimation("strokeEnd")
        strokeEndAnimation.keyTimes = [0.0, 0.05, 0.4, 1.0]
        strokeEndAnimation.values = [0, 0, 1, 1]
        
        let fillAnimation = self.createKeyframeAnimation("fillColor")
        fillAnimation.keyTimes = [0.0, 0.05, 0.4, 1.0]
        fillAnimation.values = [UIColor.clearColor().CGColor, UIColor.clearColor().CGColor, ThemeHelper.defaultVividColor.CGColor]
        fillAnimation.calculationMode = kCAAnimationDiscrete
        return self.wrapInAnimationGroup([strokeEndAnimation, fillAnimation])
    }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        circleLayer.transform = CATransform3DMakeTranslation(view.frame.width * 0.1, 0, 0)
    }
    
    
}

