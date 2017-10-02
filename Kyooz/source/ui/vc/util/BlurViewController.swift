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
			let cappedRadius = KyoozUtils.cap(blurRadius, min: 0, max: 1)
			blurRadius = cappedRadius
			visualEffectView?.layer.timeOffset = cappedRadius
		}
	}
	var blurEffect:UIBlurEffectStyle = .dark {
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
		view.backgroundColor = UIColor.clear
	}

	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if removedFromViewHierarchy {
			removedFromViewHierarchy = false
			resetBlurAnimation()
			removeSnapshotBlur()
		}
	}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerForApplicationNotifications()
    }
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		createSnapshotBlur()
		removeBlurAnimation()
		removedFromViewHierarchy = true
        unregisterForNotifications()
	}
	
    @objc func createSnapshotBlur() {
		removeSnapshotBlur()
		blurSnapshotView = view.superview?.snapshotView(afterScreenUpdates: false)
	}
	
    @objc func removeBlurAnimation() {
		visualEffectView?.removeFromSuperview()
		visualEffectView = nil
	}
	
	
	//the blur animation must be reset once it has been brought back on screen after being off screen
    @objc func resetBlurAnimation() {
		//only reset if the view has not been removed from the view hierarchy and we know that the blur animation has already been removed
		guard !removedFromViewHierarchy && self.visualEffectView == nil else { return }
		
		let visualEffectView = UIVisualEffectView()
		ConstraintUtils.applyStandardConstraintsToView(subView: visualEffectView, parentView: view)
		visualEffectView.layer.speed = 0 //setting the layer speed to 0 because we want to control the animation so that we can control the blur
        self.visualEffectView = visualEffectView
		UIView.animate(withDuration: 1) { [finalBlurEffect = self.blurEffect] in
			visualEffectView.effect = UIBlurEffect(style: finalBlurEffect)
		}
		
		KyoozUtils.doInMainQueueAsync() { [timeOffset = blurRadius] in
			visualEffectView.layer.timeOffset = timeOffset
		}
	}
	
    @objc func removeSnapshotBlur() {
		blurSnapshotView = nil
	}
    
    func registerForApplicationNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(self.createSnapshotBlur), name: NSNotification.Name.UIApplicationWillResignActive, object: UIApplication.shared)
        notificationCenter.addObserver(self, selector: #selector(self.removeBlurAnimation), name: NSNotification.Name.UIApplicationDidEnterBackground, object: UIApplication.shared)
        notificationCenter.addObserver(self, selector: #selector(self.resetBlurAnimation), name: NSNotification.Name.UIApplicationWillEnterForeground, object: UIApplication.shared)
        notificationCenter.addObserver(self, selector: #selector(self.removeSnapshotBlur), name: NSNotification.Name.UIApplicationDidBecomeActive, object: UIApplication.shared)
    }
    
    func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
	
}
