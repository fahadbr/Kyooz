//
//  AudioQueuePlayerDelegateImpl.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/19/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class AudioQueuePlayerDelegateImpl : NSObject, AudioQueuePlayerDelegate {
    
    private let presentationController:UIViewController = ContainerViewController.instance
	
	private let undoManager:NSUndoManager = {
		let u = NSUndoManager()
		u.levelsOfUndo = 2
		
		return u
	}()
    
	func audioQueuePlayerDidChangeContext(audioQueuePlayer:AudioQueuePlayer, previousSnapshot: PlaybackStateSnapshot) {
		KyoozUtils.doInMainQueueAsync() {
			self.showUndoNotificationController(audioQueuePlayer, snapshot: previousSnapshot)
		}
    }
    
    func audioQueuePlayerDidEnqueueItems(items: [AudioTrack], position: EnqueuePosition) {
        
    }
	
	private func showUndoNotificationController(audioQueuePlayer:AudioQueuePlayer, snapshot:PlaybackStateSnapshot) {
		let vc = UIStoryboard.shortNotificationViewController()
		guard let nowPlayingItem = audioQueuePlayer.nowPlayingItem else {
			return
		}
		
		
		vc.message = "Now Playing:\n\(nowPlayingItem.trackTitle) by \(nowPlayingItem.artist)"
		if !snapshot.nowPlayingQueueContext.currentQueue.isEmpty {
			vc.undoBlock = {
				audioQueuePlayer.playbackStateSnapshot = snapshot
			}
		}
		
		let size = CGSize(width: presentationController.view.frame.width * 0.85, height: 60)
		let origin = CGPoint(x: (presentationController.view.frame.width - size.width)/2, y: presentationController.view.frame.height * 0.80)
		vc.view.frame = CGRect(origin: origin, size: size)
		
		UIView.transitionWithView(presentationController.view, duration: 0.5, options: .TransitionCrossDissolve, animations: { () -> Void in
			self.presentationController.view.addSubview(vc.view)
			}) {[presentationController = self.presentationController]_ -> Void in
				presentationController.addChildViewController(vc)
				vc.didMoveToParentViewController(presentationController)
		}
	}
	
	func restorePlaybackState(stateToRestore:PlaybackStatePersistableSnapshot) {
		ApplicationDefaults.audioQueuePlayer.playbackStateSnapshot = stateToRestore.snapshot
	}
	
}