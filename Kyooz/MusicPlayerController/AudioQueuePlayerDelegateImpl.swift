//
//  AudioQueuePlayerDelegateImpl.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/19/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class AudioQueuePlayerDelegateImpl : NSObject, AudioQueuePlayerDelegate {
    
    private let shortNotificationManager = ShortNotificationManager.instance
    
	func audioQueuePlayerDidChangeContext(audioQueuePlayer:AudioQueuePlayer, previousSnapshot: PlaybackStateSnapshot) {
		KyoozUtils.doInMainQueueAsync() {
			self.registerUndoAndShowNotification(audioQueuePlayer, snapshot: previousSnapshot)
		}
    }
    
    func audioQueuePlayerDidEnqueueItems(items: [AudioTrack], position: EnqueuePosition) {
		let positionString:String
		switch position {
		case .Last:
			positionString = "Last"
		case .Next:
			positionString = "Next"
		case .Random:
			positionString = "Randomly"
		}
		KyoozUtils.doInMainQueueAsync() {
			self.shortNotificationManager.presentShortNotificationWithMessage("Queued \(items.count) tracks to play \(positionString)", withSize: .Small)
		}
    }
	
    private func registerUndoAndShowNotification(audioQueuePlayer:AudioQueuePlayer, snapshot:PlaybackStateSnapshot) {
		guard let nowPlayingItem = audioQueuePlayer.nowPlayingItem else {
			return
		}
		
        let message = "Now Playing:\n\(nowPlayingItem.trackTitle) by \(nowPlayingItem.artist).  Shake to Undo/Redo!"
		if !snapshot.nowPlayingQueueContext.currentQueue.isEmpty {
            if let undoManager = ContainerViewController.instance.undoManager {
                undoManager.registerUndoWithTarget(self, selector: #selector(AudioQueuePlayerDelegateImpl.restorePlaybackState(_:)), object: snapshot.persistableSnapshot)
                undoManager.setActionName("Queue Change")
            }
		}
		
		shortNotificationManager.presentShortNotificationWithMessage(message, withSize: .Large)
	}
	
	func restorePlaybackState(stateToRestore:PlaybackStatePersistableSnapshot) {
        let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
        let currentSnapshot = audioQueuePlayer.playbackStateSnapshot
        audioQueuePlayer.playbackStateSnapshot = stateToRestore.snapshot
        registerUndoAndShowNotification(audioQueuePlayer, snapshot: currentSnapshot)
	}
	
}