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
    
	func audioQueuePlayerDidChangeContext(_ audioQueuePlayer:AudioQueuePlayer, previousSnapshot: PlaybackStateSnapshot) {
		KyoozUtils.doInMainQueueAsync() {
			self.registerUndoAndShowNotification(audioQueuePlayer, snapshot: previousSnapshot)
		}
    }
    
    func audioQueuePlayerDidEnqueueItems(tracks tracksToEnqueue: [AudioTrack], at enqueueAction: EnqueueAction) {
		KyoozUtils.doInMainQueueAsync() {
			self.shortNotificationManager.presentShortNotification(withMessage:"Queued \(tracksToEnqueue.count) tracks to play \(enqueueAction)")
		}
    }
	
    private func registerUndoAndShowNotification(_ audioQueuePlayer:AudioQueuePlayer, snapshot:PlaybackStateSnapshot) {
		guard let nowPlayingItem = audioQueuePlayer.nowPlayingItem else {
			return
		}
		
        let message = "Now Playing:\n\(nowPlayingItem.trackTitle) by \(nowPlayingItem.artist).  Shake to Undo/Redo!"
		if !snapshot.nowPlayingQueueContext.currentQueue.isEmpty {
            if let undoManager = ContainerViewController.instance.undoManager {
                undoManager.registerUndo(withTarget: self, selector: #selector(AudioQueuePlayerDelegateImpl.restorePlaybackState(_:)), object: snapshot.persistableSnapshot)
                undoManager.setActionName("Queue Change")
            }
		}
		
        shortNotificationManager.presentShortNotification(withMessage:message)
	}
	
	func restorePlaybackState(_ stateToRestore:PlaybackStatePersistableSnapshot) {
        let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
        let currentSnapshot = audioQueuePlayer.playbackStateSnapshot
        audioQueuePlayer.playbackStateSnapshot = stateToRestore.snapshot
        registerUndoAndShowNotification(audioQueuePlayer, snapshot: currentSnapshot)
	}
	
}
