//
//  GestureActivatedSearchViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/14/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class PanTutorialViewController : TutorialViewController {
    
    private let isPanningRight:Bool
    private lazy var panAnimation:CAAnimation = {
        let offsetX = self.view.frame.width * 0.2 * (self.isPanningRight ? 1 : -1)
        let scale:CGFloat = 1.2
        let times:[NSNumber] = [0.0, 0.2, 0.8, 1.0]
        let animationTime:Double = 1
        let delay:Double = 1.5
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.duration = delay + animationTime
        groupAnimation.repeatCount = Float.infinity
        
        func createKeyframeAnimation(keyPath:String) -> CAKeyframeAnimation {
            
            let animation = CAKeyframeAnimation(keyPath: keyPath)
            animation.keyTimes = times
            animation.duration = animationTime
            animation.fillMode = kCAFillModeBoth
            animation.beginTime = delay/2
            return animation
        }
        
        let scaleAnimation = createKeyframeAnimation("transform.scale")
        scaleAnimation.values = [scale, 1, 1, scale]
        
        let translateAnimation = createKeyframeAnimation("transform.translation.x")
        translateAnimation.values = [-offsetX, -offsetX, offsetX, offsetX]
        
        let opacityAnimation = createKeyframeAnimation("opacity")
        opacityAnimation.values = [0, 1, 1, 0]
        
        let fillAnimation = createKeyframeAnimation("fillColor")
        fillAnimation.values = [UIColor.clearColor().CGColor, ThemeHelper.defaultFontColor.CGColor, UIColor.clearColor().CGColor]
        fillAnimation.calculationMode = kCAAnimationDiscrete
        
        
        groupAnimation.animations = [scaleAnimation, translateAnimation, opacityAnimation, fillAnimation]
        return groupAnimation
    }()
    
    init(tutorialDTO: TutorialDTO, isPanningRight:Bool) {
        self.isPanningRight = isPanningRight
        super.init(tutorialDTO: tutorialDTO)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        circleLayer.transform = CATransform3DMakeTranslation(0, view.frame.height * 0.15, 0)
    }
    
    override func removeAnimations() {
        circleLayer.removeAllAnimations()
        circleLayer.removeFromSuperlayer()
    }
    
    override func applyAnimation() {
        circleLayer.removeAllAnimations()
        if circleLayer.superlayer == nil {
            view.layer.addSublayer(circleLayer)
        }
        circleLayer.addAnimation(panAnimation, forKey: "tutorial")
    }
    

    
    
}
