//
//  RevealAnimator.swift
//  LogoReveal
//
//  Created by FAHAD RIAZ on 1/8/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import UIKit

final class ViewControllerFadeAnimator: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning, CAAnimationDelegate {
    
    static let instance = ViewControllerFadeAnimator()
    
    var animationDuration:Double {
        if interactive {
            return interactiveAnimationDuration
        } else {
            return 0.15
        }
    }
    let interactiveAnimationDuration = 0.5
    
    var operation:UINavigationControllerOperation = .push
    
    var interactive:Bool = false
    
    weak var storedContext:UIViewControllerContextTransitioning?
    
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        storedContext = transitionContext
        let isPushOperation = operation == .push

        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from), let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            return
        }
        
        let vcToAnimate:UIViewController
        
        let viewToAdd = toVC.view
        viewToAdd?.frame = transitionContext.finalFrame(for: toVC)
        
        if isPushOperation {
            vcToAnimate = toVC
            transitionContext.containerView.addSubview(viewToAdd!)
            
            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
            fadeAnimation.duration = animationDuration
            fadeAnimation.delegate = self
            fadeAnimation.fromValue = 0
            fadeAnimation.toValue = 1
            
            vcToAnimate.view.layer.add(fadeAnimation, forKey: nil)
        } else {
            vcToAnimate = fromVC
            transitionContext.containerView.insertSubview(viewToAdd!, belowSubview: fromVC.view)
            
            var animations = { vcToAnimate.view.alpha = 0.0 }
            if interactive {
                let transform = CGAffineTransform(translationX: vcToAnimate.view.frame.width, y: 0)
                animations = {
                    vcToAnimate.view.transform = transform
                    vcToAnimate.view.alpha = 0.0
                }
            }
            UIView.animate(withDuration: animationDuration, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: animations, completion: {_ in
                self.handleAnimationCompletion()
            })
        }

    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        handleAnimationCompletion()
    }
    
    
    private func handleAnimationCompletion() {
//        Logger.debug("completed \(operation == .Push ? "push" : "pop") animation")
        if let context = storedContext {
            context.completeTransition(!context.transitionWasCancelled)
        }
        storedContext = nil
    }
    
    final func handlePan(_ recognizer:UIPanGestureRecognizer) {
        guard let superView = recognizer.view?.superview else {
            return
        }
        let translation = recognizer.translation(in: superView)
        let screenSize = superView.bounds.size
        let widthToTravel = min(screenSize.width, screenSize.height)
        let progress:CGFloat = min(max(abs(translation.x/widthToTravel), 0.01), 0.99)
        
        switch recognizer.state {
        case .changed:
            update(progress)
        case .cancelled, .ended:
            if progress < 0.25 {
                cancel()
            } else {
                finish()
            }
            interactive = false
        default:
            break
        }
        
    }
}
