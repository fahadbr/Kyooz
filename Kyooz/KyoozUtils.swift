//
//  KyoozUtils.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/15/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import SystemConfiguration
import MediaPlayer
import StoreKit

private let mainQueueKey = UnsafeMutablePointer<Void>.alloc(1)
private let mainQueueValue = UnsafeMutablePointer<Void>.alloc(1)

func initMainQueueChecking() {
    dispatch_queue_set_specific(dispatch_get_main_queue(), mainQueueKey, mainQueueValue, nil)
}

struct KyoozUtils {
	
	static let documentsDirectory:NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
	
	static let libraryDirectory:NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
    
    private static let fadeInAnimation:CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 0.2
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.fillMode = kCAFillModeBackwards
        return animation
    }()
    
    private static let fadeOutAnimation:CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 0.5
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.removedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        return animation
    }()
    	
	static var internetConnectionAvailable:Bool {
		return KYReachability.reachabilityForInternetConnection().currentReachabilityStatus() != NetworkStatus.NotReachable
	}
    
    static var isDebugEnabled: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
    
    static var screenshotUITesting: Bool {
        #if MOCK_DATA
//			return NSProcessInfo.processInfo().arguments.contains(KyoozConstants.screenShotUITesting)
			return true
        #else
            return false
        #endif
    }
    
    static var appVersion: String? {
        return NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    static func getDispatchTimeForSeconds(seconds:Double) -> dispatch_time_t {
        return dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
    }
    
    static func fadeInAnimationWithDuration(duration:CFTimeInterval) -> CABasicAnimation {
        let animationCopy = fadeInAnimation.copy() as! CABasicAnimation
        animationCopy.duration = duration
        return animationCopy
    }
    
    static func fadeOutAnimationWithDuration(duration:CFTimeInterval) -> CABasicAnimation {
        let animationCopy = fadeOutAnimation.copy() as! CABasicAnimation
        animationCopy.duration = duration
        return animationCopy
    }
	
	//MARK: - dispatch to main queue functions
	
    static func doInMainQueueAsync(block:()->()) {
        dispatch_async(dispatch_get_main_queue(), block)
    }
    
    static func doInMainQueueSync(block:()->()) {
        if NSThread.isMainThread() {
            //execute the block if already in the main thread
            block()
        } else {
            dispatch_sync(dispatch_get_main_queue(), block)
        }
    }
    
    //performs action in main queue with no regard to weather the caller wants it done asynchronously or synchronously.
    //most performant because if not in main queue then an async dispatch will not hold up the thread.  and if already in main queue
    //then it will be executed immediately
    static func doInMainQueue(block:()->()) {
        if dispatch_get_specific(mainQueueKey) == mainQueueValue {
            block()
        } else {
            doInMainQueueAsync(block)
        }
    }
    
    static func doInMainQueueAfterDelay(delayInSeconds:Double, block:()->()) {
        dispatch_after(getDispatchTimeForSeconds(delayInSeconds), dispatch_get_main_queue(), block)
    }
	
	//MARK: - random number functions
    static func randomNumber(belowValue value:Int) -> Int {
        return Int(arc4random_uniform(UInt32(value)))
    }
    
    static func randomNumberInRange(range:Range<Int>) -> Int {
        let startIndex = range.startIndex
        let endIndex = range.endIndex
        return randomNumber(belowValue: endIndex - startIndex) + startIndex
    }
	
	//MARK: - util functions
    
    static func performWithMetrics(blockDescription description:String, block:()->()) {
        let startTime = CFAbsoluteTimeGetCurrent()
        block()
        let endTime = CFAbsoluteTimeGetCurrent()
        Logger.debug("Took \(endTime - startTime) seconds to perform \(description)")
    }
	
	static func showPopupError(withTitle title:String?, withMessage message:String?, presentationVC:UIViewController?) {
		let errorAC = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		errorAC.view.tintColor = ThemeHelper.defaultVividColor
		errorAC.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
        (presentationVC ?? ContainerViewController.instance).presentViewController(errorAC, animated: true, completion: {
            errorAC.view.tintColor = ThemeHelper.defaultVividColor
        })
	}
    
    static func showPopupError(withTitle title:String, withThrownError error:ErrorType, presentationVC:UIViewController?) {
        let message = "Error Description: \(error.description)"
        showPopupError(withTitle: title, withMessage: message, presentationVC: presentationVC)
    }
	
    static func confirmAction(actionTitle:String,
                              actionDetails:String? = nil,
                              presentingVC:UIViewController = ContainerViewController.instance,
                              action:()->()) {
		let b = MenuBuilder()
			.with(title: actionTitle)
			.with(details: actionDetails)
			.with(options: KyoozMenuAction(title: "YES", action: action))
		
		showMenuViewController(b.viewController, presentingVC: presentingVC)
	}
    
    static func showMenuViewController(kmvc:UIViewController,
                                       presentingVC:UIViewController = ContainerViewController.instance) {
        kmvc.view.frame = presentingVC.view.frame
        
        presentingVC.addChildViewController(kmvc)
        kmvc.didMoveToParentViewController(presentingVC)
        presentingVC.view.addSubview(kmvc.view)
        (presentingVC as? ContainerViewController)?.longPressGestureRecognizer?.enabled = false

    }
    
	static func addDefaultQueueingActions(tracks:[AudioTrack], menuBuilder:MenuBuilder, completionAction:(()->Void)? = nil) {
        let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
        let queueLastAction = KyoozMenuAction(title: "QUEUE LAST") {
            audioQueuePlayer.enqueue(tracks: tracks, at: .last)
            completionAction?()
        }
        let queueNextAction = KyoozMenuAction(title: "QUEUE NEXT") {
            audioQueuePlayer.enqueue(tracks: tracks, at: .next)
            completionAction?()
        }
        let queueRandomlyAction = KyoozMenuAction(title: "QUEUE RANDOMLY") {
            audioQueuePlayer.enqueue(tracks: tracks, at: .random)
            completionAction?()
        }
        
        menuBuilder.with(options: queueNextAction, queueLastAction, queueRandomlyAction)
		menuBuilder.with(options: KyoozMenuAction(title: "ADD TO PLAYLIST..") {
            let title:String? = tracks.count == 1 ? nil : "ADD \(tracks.count) TRACKS TO PLAYLIST"
            Playlists.showAvailablePlaylists(forAddingTracks: tracks,
                usingTitle: title,
                completionAction:completionAction)
        })
    }
    
    
	
	static func cap<T:Comparable>(value:T, min:T, max:T) -> T {
		if value < min {
			return min
		} else if value > max {
			return max
		}
		return value
	}
	
}