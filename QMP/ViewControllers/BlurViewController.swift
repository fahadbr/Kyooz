//
//  BlurViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/8/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class BlurViewController : UIViewController {
	
	var blurRadius:Double = 0 {
		didSet {
			let cappedRadius = min(max(blurRadius, 0), 1)
			blurRadius = cappedRadius
			visualEffectView.layer.timeOffset = cappedRadius
		}
	}
	var blurEffect:UIBlurEffectStyle = .Dark {
		didSet {
			resetBlurAnimation()
		}
	}
	
	private var blurSnapshotView:UIView? {
		willSet {
			if let snapshot = newValue {
				view.superview?.addSubview(snapshot)
			} else {
				blurSnapshotView?.removeFromSuperview()
			}
		}
	}
	
	private let visualEffectView = UIVisualEffectView()
	private var removedFromViewHierarchy = true
	private var blurAnimationRemoved = true
	
	override func viewDidLoad() {
		view.backgroundColor = UIColor.clearColor()
		view.addSubview(visualEffectView)
		visualEffectView.translatesAutoresizingMaskIntoConstraints = false
		visualEffectView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
		visualEffectView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
		visualEffectView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
		visualEffectView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
		visualEffectView.layer.speed = 0 //setting the layer speed to 0 because we want to control the animation so that we can control the blur
		
		let notificationCenter = NSNotificationCenter.defaultCenter()
		notificationCenter.addObserver(self, selector: "createSnapshotBlur", name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
		notificationCenter.addObserver(self, selector: "removeBlurAnimation", name: UIApplicationDidEnterBackgroundNotification, object: UIApplication.sharedApplication())
		notificationCenter.addObserver(self, selector: "resetBlurAnimation", name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
		notificationCenter.addObserver(self, selector: "removeSnapshotBlur", name: UIApplicationDidBecomeActiveNotification, object: UIApplication.sharedApplication())
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		if removedFromViewHierarchy {
			removedFromViewHierarchy = false
			resetBlurAnimation()
			removeSnapshotBlur()
		}
	}
	
	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		
		createSnapshotBlur()
		removeBlurAnimation()
		removedFromViewHierarchy = true
	}
	
	func createSnapshotBlur() {
		removeSnapshotBlur()
		blurSnapshotView = view.superview?.snapshotViewAfterScreenUpdates(false)
	}
	
	func removeBlurAnimation() {
		visualEffectView.layer.removeAllAnimations()
		visualEffectView.layer.timeOffset = 0
		blurAnimationRemoved = true
	}
	
	//the blur animation must be reset once it has been brought back on screen after being off screen
	func resetBlurAnimation() {
		//only reset if the view has not been removed from the view hierarchy and we know that the blur animation has already been removed
		guard !removedFromViewHierarchy && blurAnimationRemoved else { return }
		
		visualEffectView.effect = nil
		UIView.animateWithDuration(1) { [blurView = self.visualEffectView, finalBlurEffect = self.blurEffect] in
			blurView.effect = UIBlurEffect(style: finalBlurEffect)
		}
		blurAnimationRemoved = false
		
		KyoozUtils.doInMainQueueAsync() { [blurView = self.visualEffectView, timeOffset = blurRadius] in
			blurView.layer.timeOffset = timeOffset
		}
		
	}
	
	func removeSnapshotBlur() {
		blurSnapshotView = nil
	}
	
}
