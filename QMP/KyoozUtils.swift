//
//  KyoozUtils.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/15/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

struct KyoozUtils {
	
	static let documentsDirectory:NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
	
	static let libraryDirectory:NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
    
    static func getDispatchTimeForSeconds(seconds:Double) -> dispatch_time_t {
        return dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
    }
    
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
    
    static func randomNumber(belowValue value:Int) -> Int {
        return Int(arc4random_uniform(UInt32(value)))
    }
    
    static func randomNumberInRange(range:Range<Int>) -> Int {
        let startIndex = range.startIndex
        let endIndex = range.endIndex
        return randomNumber(belowValue: endIndex - startIndex) + startIndex
    }
    
    static func performWithMetrics(blockDescription description:String, block:()->()) {
        let startTime = CFAbsoluteTimeGetCurrent()
        block()
        let endTime = CFAbsoluteTimeGetCurrent()
        Logger.debug("Took \(endTime - startTime) seconds to perform \(description)")
    }
	
	static func showPopupError(withTitle title:String, withMessage message:String, presentationVC:UIViewController) {
		let errorAC = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		errorAC.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
		presentationVC.presentViewController(errorAC, animated: true, completion: nil)
	}
	
}