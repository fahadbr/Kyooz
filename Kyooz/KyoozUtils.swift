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

private let mainQueueKey = DispatchSpecificKey<Bool>()
private let mainQueueValue = true

func initMainQueueChecking() {
    DispatchQueue.main.setSpecific(key: mainQueueKey, value: mainQueueValue)
}

struct KyoozUtils {
	
	static let documentsDirectory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!, isDirectory: true)
	
	static let libraryDirectory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!, isDirectory: true)
    
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
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        return animation
    }()
    	
	static var internetConnectionAvailable:Bool {
		return KYReachability.forInternetConnection().currentReachabilityStatus() != NetworkStatus.NotReachable
	}
    
    static var isDebugEnabled: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
    
    static var usingMockData: Bool {
        #if MOCK_DATA
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
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    static func getDispatchTimeForSeconds(_ seconds:Double) -> DispatchTime {
        return DispatchTime.now() + Double(Int64(seconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    }
    
    static func fadeInAnimationWithDuration(_ duration:CFTimeInterval) -> CABasicAnimation {
        let animationCopy = fadeInAnimation.copy() as! CABasicAnimation
        animationCopy.duration = duration
        return animationCopy
    }
    
    static func fadeOutAnimationWithDuration(_ duration:CFTimeInterval) -> CABasicAnimation {
        let animationCopy = fadeOutAnimation.copy() as! CABasicAnimation
        animationCopy.duration = duration
        return animationCopy
    }
	
	//MARK: - dispatch to main queue functions
	
    static func doInMainQueueAsync(_ block:@escaping ()->()) {
        DispatchQueue.main.async(execute: block)
    }
    
    static func doInMainQueueSync(_ block:()->()) {
        if Thread.isMainThread {
            //execute the block if already in the main thread
            block()
        } else {
            DispatchQueue.main.sync(execute: block)
        }
    }
    
    //performs action in main queue with no regard to weather the caller wants it done asynchronously or synchronously.
    //most performant because if not in main queue then an async dispatch will not hold up the thread.  and if already in main queue
    //then it will be executed immediately
    static func doInMainQueue(_ block:@escaping ()->()) {
        if DispatchQueue.getSpecific(key: mainQueueKey) == mainQueueValue {
            block()
        } else {
            doInMainQueueAsync(block)
        }
    }
    
    static func doInMainQueueAfterDelay(_ delayInSeconds:Double, block:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(deadline: getDispatchTimeForSeconds(delayInSeconds), execute: block)
    }
	
	//MARK: - random number functions
    static func randomNumber(belowValue value:Int) -> Int {
        return Int(arc4random_uniform(UInt32(abs(value))))
    }
    
    static func randomNumber(in range:Range<Int>) -> Int {
        let startIndex = range.lowerBound
        let endIndex = range.upperBound
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
		let errorAC = UIAlertController(title: title, message: message, preferredStyle: .alert)
		errorAC.view.tintColor = ThemeHelper.defaultVividColor
		errorAC.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        (presentationVC ?? ContainerViewController.instance).present(errorAC, animated: true, completion: {
            errorAC.view.tintColor = ThemeHelper.defaultVividColor
        })
	}
    
    static func showPopupError(withTitle title:String, withThrownError error:Error, presentationVC:UIViewController?) {
        let message = "Error Description: \(error.description)"
        showPopupError(withTitle: title, withMessage: message, presentationVC: presentationVC)
    }
	
    static func confirmAction(_ actionTitle:String,
                              actionDetails:String? = nil,
                              presentingVC:UIViewController = ContainerViewController.instance,
                              action: @escaping ()->()) {
		let b = MenuBuilder()
			.with(title: actionTitle)
			.with(details: actionDetails)
			.with(options: KyoozMenuAction(title: "YES", action: action))
		
		showMenuViewController(b.viewController, presentingVC: presentingVC)
	}
    
    static func showMenuViewController(_ kmvc:UIViewController,
                                       presentingVC:UIViewController = ContainerViewController.instance) {
        kmvc.view.frame = presentingVC.view.frame
        
        presentingVC.addChildViewController(kmvc)
        kmvc.didMove(toParentViewController: presentingVC)
        presentingVC.view.addSubview(kmvc.view)
        (presentingVC as? ContainerViewController)?.longPressGestureRecognizer?.isEnabled = false

    }
    
	static func addDefaultQueueingActions(_ tracks:[AudioTrack], menuBuilder:MenuBuilder, completionAction:(()->Void)? = nil) {
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
    
    
	
	static func cap<T:Comparable>(_ value:T, min:T, max:T) -> T {
		if value < min {
			return min
		} else if value > max {
			return max
		}
		return value
	}
	
}
