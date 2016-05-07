//
//  AudioQueuePlayerWrapper.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/11/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

final class AudioQueuePlayerWrapper : AudioQueuePlayer {
	
	private let delegateAudioQueuePlayer:AudioQueuePlayer
	
	init(delegateAudioQueuePlayer:AudioQueuePlayer) {
		self.delegateAudioQueuePlayer = delegateAudioQueuePlayer
	}
	
	var type:AudioQueuePlayerType {
		get { return delegateAudioQueuePlayer.type }
	}
	var playbackStateSnapshot:PlaybackStateSnapshot {
		get { return delegateAudioQueuePlayer.playbackStateSnapshot }
		set { delegateAudioQueuePlayer.playbackStateSnapshot = newValue }
	}
	
	var nowPlayingItem:AudioTrack? {
		get { return delegateAudioQueuePlayer.nowPlayingItem }
	}
	
	var musicIsPlaying:Bool {
		get { return delegateAudioQueuePlayer.musicIsPlaying}
	}
	
	var currentPlaybackTime:Float {
		get { return delegateAudioQueuePlayer.currentPlaybackTime }
		set {
			delegateAudioQueuePlayer.currentPlaybackTime = newValue
			publishNotification(updateType: .PlaybackStateUpdate, sender: delegateAudioQueuePlayer)
		}
	}
	
	var indexOfNowPlayingItem:Int {
		get { return delegateAudioQueuePlayer.indexOfNowPlayingItem }
	}
	
	var nowPlayingQueue:[AudioTrack] {
		get { return delegateAudioQueuePlayer.nowPlayingQueue }
	}
	var shuffleActive:Bool {
		get { return delegateAudioQueuePlayer.shuffleActive }
		set {
			delegateAudioQueuePlayer.shuffleActive = newValue
			publishNotification(updateType: .SystematicQueueUpdate, sender: delegateAudioQueuePlayer)
		}
	}
	var repeatMode:RepeatState {
		get { return delegateAudioQueuePlayer.repeatMode }
		set {
			delegateAudioQueuePlayer.repeatMode = newValue
			publishNotification(updateType: .SystematicQueueUpdate, sender: delegateAudioQueuePlayer)
		}
	}
	
	var delegate:AudioQueuePlayerDelegate? {
		get { return delegateAudioQueuePlayer.delegate }
		set { delegateAudioQueuePlayer.delegate = newValue }
	}
	
	func play() {
		delegateAudioQueuePlayer.play()
	}
	
	func pause() {
		delegateAudioQueuePlayer.pause()
	}
	
	func skipBackwards(forcePreviousTrack:Bool) {
		delegateAudioQueuePlayer.skipBackwards(forcePreviousTrack)
	}
	
	func skipForwards() {
		delegateAudioQueuePlayer.skipForwards()
	}
	
	func playNow(withTracks tracks:[AudioTrack], startingAtIndex index:Int, shouldShuffleIfOff:Bool) {
		let oldSnapshot = playbackStateSnapshot
		delegateAudioQueuePlayer.playNow(withTracks: tracks, startingAtIndex: index, shouldShuffleIfOff: shouldShuffleIfOff)
		publishNotification(updateType: .QueueUpdate, sender: delegateAudioQueuePlayer)
		delegate?.audioQueuePlayerDidChangeContext(delegateAudioQueuePlayer, previousSnapshot:oldSnapshot)
		
	}
	
	func playItemWithIndexInCurrentQueue(index index:Int) {
		delegateAudioQueuePlayer.playItemWithIndexInCurrentQueue(index: index)
	}
	
	func enqueue(items itemsToEnqueue:[AudioTrack], atPosition position:EnqueuePosition) {
		delegateAudioQueuePlayer.enqueue(items: itemsToEnqueue, atPosition: position)
		publishNotification(updateType: .QueueUpdate, sender: delegateAudioQueuePlayer)
		delegate?.audioQueuePlayerDidEnqueueItems(itemsToEnqueue, position: position)
	}
	
	//returns the number of items inserted
	func insertItemsAtIndex(itemsToInsert:[AudioTrack], index:Int) -> Int {
		publishNotification(updateType: .QueueUpdate, sender: delegateAudioQueuePlayer)
		return delegateAudioQueuePlayer.insertItemsAtIndex(itemsToInsert, index: index)
	}
	
	func deleteItemsAtIndices(indicies:[Int]) {
		delegateAudioQueuePlayer.deleteItemsAtIndices(indicies)
		publishNotification(updateType: .QueueUpdate, sender: delegateAudioQueuePlayer)
	}
	
	func moveMediaItem(fromIndexPath fromIndexPath:Int, toIndexPath:Int) {
		delegateAudioQueuePlayer.moveMediaItem(fromIndexPath: fromIndexPath, toIndexPath: toIndexPath)
		publishNotification(updateType: .QueueUpdate, sender: delegateAudioQueuePlayer)
	}
	
	func clearItems(towardsDirection direction:ClearDirection, atIndex index:Int) {
		delegateAudioQueuePlayer.clearItems(towardsDirection: direction, atIndex: index)
		publishNotification(updateType: .QueueUpdate, sender: delegateAudioQueuePlayer)
	}
	
}
