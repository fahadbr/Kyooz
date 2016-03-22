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
			visualEffectView?.layer.timeOffset = cappedRadius
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
	
	private var visualEffectView:UIVisualEffectView?
	private var removedFromViewHierarchy = true
	
	override func viewDidLoad() {
		view.backgroundColor = UIColor.clearColor()
		
		let notificationCenter = NSNotificationCenter.defaultCenter()
		notificationCenter.addObserver(self, selector: #selector(BlurViewController.createSnapshotBlur), name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
		notificationCenter.addObserver(self, selector: #selector(BlurViewController.removeBlurAnimation), name: UIApplicationDidEnterBackgroundNotification, object: UIApplication.sharedApplication())
		notificationCenter.addObserver(self, selector: #selector(BlurViewController.resetBlurAnimation), name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
		notificationCenter.addObserver(self, selector: #selector(BlurViewController.removeSnapshotBlur), name: UIApplicationDidBecomeActiveNotification, object: UIApplication.sharedApplication())
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
		visualEffectView?.removeFromSuperview()
		visualEffectView = nil
	}
	
	
	//the blur animation must be reset once it has been brought back on screen after being off screen
	func resetBlurAnimation() {
		//only reset if the view has not been removed from the view hierarchy and we know that the blur animation has already been removed
		guard !removedFromViewHierarchy && self.visualEffectView == nil else { return }
		
		let visualEffectView = UIVisualEffectView()
		ConstraintUtils.applyStandardConstraintsToView(subView: visualEffectView, parentView: view)
		visualEffectView.layer.speed = 0 //setting the layer speed to 0 because we want to control the animation so that we can control the blur
        self.visualEffectView = visualEffectView
		UIView.animateWithDuration(1) { [finalBlurEffect = self.blurEffect] in
			visualEffectView.effect = UIBlurEffect(style: finalBlurEffect)
		}
		
		KyoozUtils.doInMainQueueAsync() { [timeOffset = blurRadius] in
			visualEffectView.layer.timeOffset = timeOffset
		}
	}
	
	func removeSnapshotBlur() {
		blurSnapshotView = nil
	}
	
}
