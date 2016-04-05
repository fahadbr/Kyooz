//
//  PlaybackProgressBarViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/4/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class PlaybackProgressBarViewController: UIViewController {
	
	let progressSlider = UISlider()
	private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
	
	private let timeProgressedLabel = UILabel()
	private let timeRemainingLabel = UILabel()
	private var stackView:UIStackView!
	
	private var playbackProgressTimer:NSTimer?

    override func viewDidLoad() {
        super.viewDidLoad()

		func configureLabel(label:UILabel) {
			label.font = ThemeHelper.defaultFont?.fontWithSize(10)
			label.textColor = ThemeHelper.defaultFontColor
			label.text = "000:00"
			label.frame.size = label.textRectForBounds(UIScreen.mainScreen().bounds, limitedToNumberOfLines: 1).size
		}
		
		configureLabel(timeProgressedLabel)
		configureLabel(timeRemainingLabel)
		
		progressSlider.minimumTrackTintColor = UIColor.whiteColor()
		progressSlider.maximumTrackTintColor = UIColor.blackColor()
		progressSlider.thumbTintColor = UIColor.lightGrayColor()
		progressSlider.addTarget(self, action: #selector(self.updatePlaybackProgressTimer), forControlEvents: .TouchCancel)
		progressSlider.addTarget(self, action: #selector(self.updatePlaybackTime(_:)), forControlEvents: .ValueChanged)
		let touchUpEvents = UIControlEvents.TouchUpOutside.union(.TouchUpInside)
		progressSlider.addTarget(self, action: #selector(self.commitUpdateOfPlaybackTime(_:)), forControlEvents: touchUpEvents)
		progressSlider.setContentHuggingPriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
		
		stackView = UIStackView(arrangedSubviews: [timeProgressedLabel, progressSlider, timeRemainingLabel])
		stackView.axis = .Horizontal
		stackView.alignment = .Center
		stackView.distribution = .Fill
		
    }
	
	func commitUpdateOfPlaybackTime(sender: UISlider) {
		audioQueuePlayer.currentPlaybackTime = sender.value
		progressSlider.value = sender.value
		//leave the timer invalidated because changing the value will trigger a notification from the music player
		//causing the view to reload and the timer to be reinitialized
		//this is preferred because we dont want the timer to start until after the seeking to the time has completed
	}
	
	func updatePlaybackTime(sender: UISlider) {
		invalidateTimer()
		let sliderValue = sender.value
		let remainingPlaybackTime = Float(audioQueuePlayer.nowPlayingItem?.playbackDuration ?? 0.0) - sliderValue
		updatePlaybackProgressBarTimeLabels(currentPlaybackTime: sliderValue, remainingPlaybackTime: remainingPlaybackTime)
	}

	
	func updatePlaybackProgressTimer() {
		if(audioQueuePlayer.musicIsPlaying && playbackProgressTimer == nil) {
			Logger.debug("initiating playbackProgressTimer")
			KyoozUtils.doInMainQueue() {
				self.playbackProgressTimer = NSTimer.scheduledTimerWithTimeInterval(1.0,
					target: self,
					selector: #selector(self.updatePlaybackProgressBar(_:)),
					userInfo: nil,
					repeats: true)
			}
		} else if(!audioQueuePlayer.musicIsPlaying && playbackProgressTimer != nil){
			invalidateTimer()
		}
	}
	
	func invalidateTimer() {
		playbackProgressTimer?.invalidate()
		playbackProgressTimer = nil
	}
	
	func updatePlaybackProgressBar(sender:NSTimer?) {
		if(audioQueuePlayer.nowPlayingItem == nil) {
			timeRemainingLabel.text = MediaItemUtils.zeroTime
			timeProgressedLabel.text = MediaItemUtils.zeroTime
			progressSlider.setValue(0.0, animated: false)
			return
		}
		let currentPlaybackTime = audioQueuePlayer.currentPlaybackTime
		let totalPlaybackTime = Float(audioQueuePlayer.nowPlayingItem!.playbackDuration)
		let remainingPlaybackTime = totalPlaybackTime - currentPlaybackTime
		
		updatePlaybackProgressBarTimeLabels(currentPlaybackTime:currentPlaybackTime, remainingPlaybackTime:remainingPlaybackTime)
		let progress = currentPlaybackTime
		progressSlider.setValue(progress, animated: true)
	}
	
	func updatePlaybackProgressBarTimeLabels(currentPlaybackTime currentPlaybackTime:Float, remainingPlaybackTime:Float) {
		timeRemainingLabel.text = "-\(MediaItemUtils.getTimeRepresentation(remainingPlaybackTime))"
		timeProgressedLabel.text = MediaItemUtils.getTimeRepresentation(currentPlaybackTime)
	}


}
