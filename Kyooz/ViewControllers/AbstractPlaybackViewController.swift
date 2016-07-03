//
//  AbstractPlaybackViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/6/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class AbstractPlaybackViewController : UIViewController {
	
	let playPauseButton = PlayPauseButtonView()
	let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
	
	override func viewDidLoad() {
		super.viewDidLoad()
		playPauseButton.addTarget(self, action: #selector(self.togglePlayPause), forControlEvents: .TouchUpInside)
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		registerForNotifications()
	}
	
	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		unregisterForNotifications()
	}
	
	func updateButtonStates() {
		playPauseButton.isPlayButton = !audioQueuePlayer.musicIsPlaying
	}
	
	func togglePlayPause() {
		if audioQueuePlayer.musicIsPlaying {
			audioQueuePlayer.pause()
		} else {
			audioQueuePlayer.play()
		}
	}
	
	func registerForNotifications() {
		let notificationCenter = NSNotificationCenter.defaultCenter()
		let application = UIApplication.sharedApplication()
		notificationCenter.addObserver(self, selector: #selector(self.updateButtonStates),
		                               name: AudioQueuePlayerUpdate.playbackStateUpdate.rawValue, object: audioQueuePlayer)
		
		notificationCenter.addObserver(self, selector: #selector(self.updateButtonStates),
		                               name: UIApplicationDidBecomeActiveNotification, object: application)
	}
	
	func unregisterForNotifications() {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
}

