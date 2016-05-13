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
		func addConstraint(view:UIView, constant:CGFloat) {
			view.translatesAutoresizingMaskIntoConstraints = false
			view.heightAnchor.constraintEqualToConstant(constant).active = true
			view.widthAnchor.constraintEqualToAnchor(view.heightAnchor).active = true
		}
		
        playPauseButton.hasOuterFrame = false
		shuffleButton.addTarget(self, action: #selector(self.toggleShuffle(_:)), forControlEvents: .TouchUpInside)
		skipBackButton.addTarget(self, action: #selector(self.skipBackward(_:)), forControlEvents: .TouchUpInside)
		skipForwardButton.addTarget(self, action: #selector(self.skipForward(_:)), forControlEvents: .TouchUpInside)
		repeatButton.addTarget(self, action: #selector(self.switchRepeatMode(_:)), forControlEvents: .TouchUpInside)
		
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
		stackView.axis = .Horizontal
		stackView.alignment = .Center
		stackView.distribution = .EqualSpacing
		
		ConstraintUtils.applyStandardConstraintsToView(subView: stackView, parentView: view)
	}
	
	override func updateButtonStates() {
		super.updateButtonStates()
		repeatButton.repeatState = audioQueuePlayer.repeatMode
		shuffleButton.isActive = audioQueuePlayer.shuffleActive
	}
	
	func skipBackward(sender: AnyObject) {
		audioQueuePlayer.skipBackwards(false)
	}
	
	func skipForward(sender: AnyObject) {
		audioQueuePlayer.skipForwards()
	}
	
	func playPauseAction(sender: AnyObject) {
		if(audioQueuePlayer.musicIsPlaying) {
			self.audioQueuePlayer.pause()
		} else {
			self.audioQueuePlayer.play()
		}
	}
	
	func toggleShuffle(sender: AnyObject) {
		let newState = !audioQueuePlayer.shuffleActive
		audioQueuePlayer.shuffleActive = newState
		shuffleButton.isActive = audioQueuePlayer.shuffleActive
	}
	
	func switchRepeatMode(sender: AnyObject) {
		let newState = audioQueuePlayer.repeatMode.nextState
		audioQueuePlayer.repeatMode = newState
		repeatButton.repeatState = audioQueuePlayer.repeatMode
	}
	
	override func registerForNotifications() {
		super.registerForNotifications()
		NSNotificationCenter.defaultCenter()
			.addObserver(self, selector: #selector(self.updateButtonStates),
			             name: AudioQueuePlayerUpdate.SystematicQueueUpdate.rawValue, object: audioQueuePlayer)
	}
	
}