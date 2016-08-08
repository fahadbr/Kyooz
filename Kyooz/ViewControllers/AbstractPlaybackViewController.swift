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
		playPauseButton.addTarget(self, action: #selector(self.togglePlayPause), for: .touchUpInside)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		registerForNotifications()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
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
		let notificationCenter = NotificationCenter.default
		let application = UIApplication.shared
		notificationCenter.addObserver(self, selector: #selector(self.updateButtonStates),
		                               name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.playbackStateUpdate.rawValue), object: audioQueuePlayer)
		
		notificationCenter.addObserver(self, selector: #selector(self.updateButtonStates),
		                               name: NSNotification.Name.UIApplicationDidBecomeActive, object: application)
	}
	
	func unregisterForNotifications() {
		NotificationCenter.default.removeObserver(self)
	}
}

