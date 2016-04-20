//
//  KyoozUtils.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/15/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import SystemConfiguration

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
	
	static var internetConnectionAvailable:Bool {
		return Reachability.reachabilityForInternetConnection().currentReachabilityStatus() != NetworkStatus.NotReachable
	}
    
    static func getDispatchTimeForSeconds(seconds:Double) -> dispatch_time_t {
        return dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
    }
    
    static func fadeInAnimationWithDuration(duration:CFTimeInterval) -> CABasicAnimation {
        let animationCopy = fadeInAnimation.copy() as! CABasicAnimation
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
        if NSThread.isMainThread() {
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
		errorAC.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
		(presentationVC ?? ContainerViewController.instance).presentViewController(errorAC, animated: true, completion: nil)
	}
    
    static func showPopupError(withTitle title:String, withThrownError error:ErrorType, presentationVC:UIViewController?) {
        let message = "Error Description: \((error as? KyoozErrorProtocol)?.errorDescription ?? "\(error.dynamicType)")"
        showPopupError(withTitle: title, withMessage: message, presentationVC: presentationVC)
    }
    
    static func showMenuViewController(kmvc:KyoozMenuViewController) {
        let presentingVC = ContainerViewController.instance
        kmvc.view.frame = presentingVC.view.frame
        
        presentingVC.addChildViewController(kmvc)
        kmvc.didMoveToParentViewController(presentingVC)
        presentingVC.view.addSubview(kmvc.view)
        kmvc.view.layer.addAnimation(fadeInAnimation, forKey: nil)
        presentingVC.longPressGestureRecognizer?.enabled = false

    }
    
    static func addDefaultQueueingActions(tracks:[AudioTrack], menuController:KyoozMenuViewController, completionAction:(()->Void)? = nil) {
        let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
        let queueLastAction = KyoozMenuAction(title: "Queue Last", image: nil) {
            audioQueuePlayer.enqueue(items: tracks, atPosition: .Last)
            completionAction?()
        }
        let queueNextAction = KyoozMenuAction(title: "Queue Next", image: nil) {
            audioQueuePlayer.enqueue(items: tracks, atPosition: .Next)
            completionAction?()
        }
        let queueRandomlyAction = KyoozMenuAction(title: "Queue Randomly", image: nil) {
            audioQueuePlayer.enqueue(items: tracks, atPosition: .Random)
            completionAction?()
        }
        
        menuController.addAction(queueNextAction)
        menuController.addAction(queueLastAction)
        menuController.addAction(queueRandomlyAction)
        menuController.addAction(KyoozMenuAction(title: "Add to Playlist..", image: nil) {
            KyoozUtils.showAvailablePlaylistsForAddingTracks(tracks)
        })
    }
    
    static func showAvailablePlaylistsForAddingTracks(tracks:[AudioTrack], completionAction:(()->Void)? = nil) {
        let ac = UIAlertController(title: "Select the playlist to add to", message: "\(tracks.count) tracks", preferredStyle: .ActionSheet)
        for obj in KyoozPlaylistManager.instance.playlists {
            guard let playlist = obj as? KyoozPlaylist else { return }
            ac.addAction(UIAlertAction(title: playlist.name, style: .Default, handler: { _ -> Void in
                var playlistTracks = playlist.tracks
                playlistTracks.appendContentsOf(tracks)
                do {
                    try KyoozPlaylistManager.instance.createOrUpdatePlaylist(playlist, withTracks: playlistTracks)
                    completionAction?()
                } catch let error {
                    showPopupError(withTitle: "Failed to add \(tracks.count) tracks to playlist: \(playlist.name)", withThrownError: error, presentationVC: nil)
                }
            }))
        }
        ac.addAction(UIAlertAction(title: "New Playlist..", style: .Default) { _ -> Void in
            showPlaylistCreationControllerForTracks(tracks, completionAction: completionAction)
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        ContainerViewController.instance.presentViewController(ac, animated: true, completion: nil)
    }
    
    static func showPlaylistCreationControllerForTracks(tracks:[AudioTrack], completionAction:(()->Void)? = nil) {
        let ac = UIAlertController(title: "Save as Playlist", message: "Enter the name you would like to save the playlist as", preferredStyle: .Alert)
        ac.addTextFieldWithConfigurationHandler(nil)
        let saveAction = UIAlertAction(title: "Save", style: .Default, handler: { (action) -> Void in
            guard let text = ac.textFields?.first?.text else {
                Logger.error("No name found")
                return
            }
            do {
                try KyoozPlaylistManager.instance.createOrUpdatePlaylist(KyoozPlaylist(name: text), withTracks: tracks)
                completionAction?()
            } catch let error {
                showPopupError(withTitle: "Failed to save playlist with name \(text)", withThrownError: error, presentationVC: nil)
            }
            
        })
        ac.addAction(saveAction)
        ac.preferredAction = saveAction
        ac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        ContainerViewController.instance.presentViewController(ac, animated: true, completion: nil)

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