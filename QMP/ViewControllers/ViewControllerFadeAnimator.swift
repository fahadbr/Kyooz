//
//  RevealAnimator.swift
//  LogoReveal
//
//  Created by FAHAD RIAZ on 1/8/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import UIKit

final class ViewControllerFadeAnimator: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {
    
    static let instance = ViewControllerFadeAnimator()
    
    var animationDuration:Double {
        if interactive {
            return interactiveAnimationDuration
        } else {
            return 0.15
        }
    }
    let interactiveAnimationDuration = 0.5
    
    var operation:UINavigationControllerOperation = .Push
    
    var interactive:Bool = false
    
    weak var storedContext:UIViewControllerContextTransitioning?
    
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return animationDuration
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        storedContext = transitionContext
        let isPushOperation = operation == .Push

        guard let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey), let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) else {
            return
        }
        
        let vcToAnimate:UIViewController
        
        let viewToAdd = toVC.view
        viewToAdd.frame = transitionContext.finalFrameForViewController(toVC)
        
        if isPushOperation {
            vcToAnimate = toVC
            transitionContext.containerView()?.addSubview(viewToAdd)
            
            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
            fadeAnimation.duration = animationDuration
            fadeAnimation.delegate = self
            fadeAnimation.fromValue = 0
            fadeAnimation.toValue = 1
            
            vcToAnimate.view.layer.addAnimation(fadeAnimation, forKey: nil)
        } else {
            vcToAnimate = fromVC
            transitionContext.containerView()?.insertSubview(viewToAdd, belowSubview: fromVC.view)
            
            var animations = { vcToAnimate.view.layer.opacity = 0.0 }
            if interactive {
                let transform = CATransform3DMakeTranslation(vcToAnimate.view.frame.width * 0.75, 0, 0)
                animations = {
                    vcToAnimate.view.layer.transform = transform
                    vcToAnimate.view.layer.opacity = 0.0
                }
            }
            UIView.animateWithDuration(animationDuration, animations: animations) {_ in
                    self.handleAnimationCompletion()
            }
        }

    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        handleAnimationCompletion()
    }
    
    
    private func handleAnimationCompletion() {
//        Logger.debug("completed \(operation == .Push ? "push" : "pop") animation")
        if let context = storedContext {
            context.completeTransition(!context.transitionWasCancelled())
        }
        storedContext = nil
    }
    
    final func handlePan(recognizer:UIPanGestureRecognizer) {
        guard let superView = recognizer.view?.superview else {
            return
        }
        let translation = recognizer.translationInView(superView)
        let progress:CGFloat = min(max(abs(translation.x/300), 0.01), 0.99)
        
        switch recognizer.state {
        case .Changed:
            updateInteractiveTransition(progress)
        case .Cancelled, .Ended:
            if progress < 0.5 {
                cancelInteractiveTransition()
            } else {
                finishInteractiveTransition()
            }
            interactive = false
        default:
            break
        }
        
    }
}
