//
//  PlaybackControlsViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/8/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class PlaybackControlsViewController : AbstractPlaybackViewController {
	
	private let skipBackButton = SkipTrackButtonView()
	private let skipForwardButton = SkipTrackButtonView()
	private let shuffleButton = ShuffleButtonView()
	private let repeatButton = RepeatButtonView()
	
	private var stackView:UIStackView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		func addConstraint(_ view:UIView, constant:CGFloat) {
			view.translatesAutoresizingMaskIntoConstraints = false
			view.heightAnchor.constraint(equalToConstant: constant).isActive = true
			view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true
		}
		
        playPauseButton.hasOuterFrame = false
		shuffleButton.addTarget(self, action: #selector(self.toggleShuffle(_:)), for: .touchUpInside)
		skipBackButton.addTarget(self, action: #selector(self.skipBackward(_:)), for: .touchUpInside)
		skipForwardButton.addTarget(self, action: #selector(self.skipForward(_:)), for: .touchUpInside)
		repeatButton.addTarget(self, action: #selector(self.switchRepeatMode(_:)), for: .touchUpInside)
		
        let inactiveColor = UIColor(white: 1, alpha: ThemeHelper.defaultButtonTextAlpha)
        shuffleButton.color = inactiveColor
        repeatButton.color = inactiveColor
        
		skipForwardButton.isForwardButton = true
		
		let viewArray = [shuffleButton, skipBackButton, playPauseButton, skipForwardButton, repeatButton]
		viewArray.forEach() {
			let constant:CGFloat
			$0.alpha = 0.8
			if $0 is SkipTrackButtonView {
				($0 as? SkipTrackButtonView)?.scale = 0.9
				constant = 45
			} else if $0 is PlayPauseButtonView {
				constant = 50
			} else {
//				$0.alpha = 0.6
				constant = 40
			}
			addConstraint($0, constant: constant)
		}
		
		stackView = UIStackView(arrangedSubviews: viewArray)
		stackView.axis = .horizontal
		stackView.alignment = .center
		stackView.distribution = .equalSpacing
		
		_ = ConstraintUtils.applyStandardConstraintsToView(subView: stackView, parentView: view)
	}
	
	override func updateButtonStates() {
		super.updateButtonStates()
		repeatButton.repeatState = audioQueuePlayer.repeatMode
		shuffleButton.isActive = audioQueuePlayer.shuffleActive
	}
	
	func skipBackward(_ sender: AnyObject) {
		audioQueuePlayer.skipBackwards(false)
	}
	
	func skipForward(_ sender: AnyObject) {
		audioQueuePlayer.skipForwards()
	}
	
	func playPauseAction(_ sender: AnyObject) {
		if(audioQueuePlayer.musicIsPlaying) {
			self.audioQueuePlayer.pause()
		} else {
			self.audioQueuePlayer.play()
		}
	}
	
	func toggleShuffle(_ sender: AnyObject) {
		let newState = !audioQueuePlayer.shuffleActive
		audioQueuePlayer.shuffleActive = newState
		shuffleButton.isActive = audioQueuePlayer.shuffleActive
	}
	
	func switchRepeatMode(_ sender: AnyObject) {
		let newState = audioQueuePlayer.repeatMode.nextState
		audioQueuePlayer.repeatMode = newState
		repeatButton.repeatState = audioQueuePlayer.repeatMode
	}
	
	override func registerForNotifications() {
		super.registerForNotifications()
		NotificationCenter.default
			.addObserver(self, selector: #selector(self.updateButtonStates),
			             name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.systematicQueueUpdate.rawValue), object: audioQueuePlayer)
	}
	
}
