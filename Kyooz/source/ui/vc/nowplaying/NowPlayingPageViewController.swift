//
//  NowPlayingPageViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/10/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class NowPlayingPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
	
	var refreshNeeded:Bool = false
	private lazy var audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
	
	override func viewDidLoad() {
		super.viewDidLoad()
		delegate = self
		dataSource = self
	}
    

	private func wrapperVCForIndex(_ index:Int, completionBlock:(()->())? = nil) -> WrapperViewController? {
		//use this to fix a but where the pageViewController caches the result of the 'viewControllerBefore/AfterViewController'
		//call.  when this is true for the corresponding pageVC then we reset the current vc so that it clears its before and after pages
		refreshNeeded = true
		
		let queue = audioQueuePlayer.nowPlayingQueue
		guard index >= 0 && !queue.isEmpty && index < queue.count else {
			return nil
		}
		let track = queue[index]

		let vc = getWrapperVCForTrack(track, index: index)
		vc.completionBlock = completionBlock
		return vc
	}
	
	fileprivate func getWrapperVCForTrack(_ track:AudioTrack, index:Int) -> WrapperViewController {
		fatalError("this method needs to be overridden")
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		let index = (viewController as? WrapperViewController)?.representingIndex ?? audioQueuePlayer.indexOfNowPlayingItem
		return wrapperVCForIndex(index + 1) { [audioQueuePlayer = self.audioQueuePlayer] in
			audioQueuePlayer.skipForwards()
		}
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		let index = (viewController as? WrapperViewController)?.representingIndex ?? audioQueuePlayer.indexOfNowPlayingItem
		return wrapperVCForIndex(index - 1) { [audioQueuePlayer = self.audioQueuePlayer] in
			audioQueuePlayer.skipBackwards(true)
		}
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
		if completed {
			(pageViewController.viewControllers?.first as? WrapperViewController)?.completionBlock?()
		}
	}

}

final class LabelPageViewController : NowPlayingPageViewController {
	fileprivate override func getWrapperVCForTrack(_ track: AudioTrack, index:Int) -> WrapperViewController {
		return LabelStackWrapperViewController(track: track, isPresentedVC: false, representingIndex: index)
	}
}

final class ImagePageViewController : NowPlayingPageViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.shadowOpacity = 0.8
        view.layer.shadowOffset = CGSize(width: 0, height: 3)
        view.layer.shadowRadius = 10
        view.clipsToBounds = false
    }
    
	fileprivate override func getWrapperVCForTrack(_ track: AudioTrack, index:Int) -> WrapperViewController {
		return ImageWrapperViewController(track: track, isPresentedVC: false, representingIndex:index, size: view.frame.size)
	}
}
