//
//  PlaybackProgressViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/4/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

protocol PlaybackProgressObserver : class {
    func updateProgress(percentComplete:Float)
}

final class PlaybackProgressViewController: UIViewController {
	
	static let instance = PlaybackProgressViewController()
	
	private let progressSlider = UISlider()
	private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
	
	private let timeProgressedLabel = UILabel()
	private let timeRemainingLabel = UILabel()
	
	private var playbackProgressTimer:NSTimer?
    private var observers = [PlaybackProgressObserver]()

    override func viewDidLoad() {
        super.viewDidLoad()

		func configureLabel(label:UILabel) {
			label.font = ThemeHelper.defaultFont?.fontWithSize(ThemeHelper.smallFontSize - 1)
			label.textColor = ThemeHelper.defaultFontColor
            label.textAlignment = .Center
			label.text = "000:00"
            label.alpha = 0.6
            label.frame.size = label.textRectForBounds(UIScreen.mainScreen().bounds, limitedToNumberOfLines: 1).size
            
            view.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.heightAnchor.constraintEqualToConstant(label.frame.height).active = true
            label.widthAnchor.constraintEqualToConstant(label.frame.width).active = true
            label.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true
		}
		
        let margin:CGFloat = 4
        configureLabel(timeProgressedLabel)
        timeProgressedLabel.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: margin).active = true
        configureLabel(timeRemainingLabel)
        timeRemainingLabel.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: -margin).active = true
        
        view.addSubview(progressSlider)
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.leftAnchor.constraintEqualToAnchor(timeProgressedLabel.rightAnchor, constant: margin).active = true
        progressSlider.rightAnchor.constraintEqualToAnchor(timeRemainingLabel.leftAnchor, constant: -margin).active = true
        progressSlider.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true
        let trackAlpha:CGFloat = 0.4
//        progressSlider.minimumTrackTintColor = UIColor(white: 1, alpha: trackAlpha)
		progressSlider.minimumTrackTintColor = ThemeHelper.defaultVividColor
        progressSlider.maximumTrackTintColor = UIColor(white: 0, alpha: trackAlpha)

        let thumbView = UIView(frame: CGRect(x: 0, y: 0, width: 7, height: 20))
        thumbView.backgroundColor = UIColor.lightGrayColor()
        thumbView.layer.cornerRadius = 2
        thumbView.layer.masksToBounds = true
        let thumbImage = ImageHelper.imageForView(thumbView, opaque: false)
        progressSlider.setThumbImage(thumbImage, forState: .Normal)
        progressSlider.setThumbImage(thumbImage, forState: .Selected)
        progressSlider.setThumbImage(thumbImage, forState: .Highlighted)

		progressSlider.addTarget(self, action: #selector(self.resetTimer), forControlEvents: .TouchCancel)
		progressSlider.addTarget(self, action: #selector(self.updateLabelsWithSlider(_:)), forControlEvents: .ValueChanged)
		let touchUpEvents = UIControlEvents.TouchUpOutside.union(.TouchUpInside)
		progressSlider.addTarget(self, action: #selector(self.commitUpdateOfPlaybackTime(_:)), forControlEvents: touchUpEvents)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        resetTimer()
        registerForNotifications()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        invalidateTimer()
        unregisterForNotifications()
    }
    
    func addProgressObserver(observer:PlaybackProgressObserver) {
        guard !observers.contains({ $0 === observer }) else { return }
        observers.append(observer)
    }
    
    func removeProgressObserver(observer:PlaybackProgressObserver) {
        guard let index = observers.indexOf( { $0 === observer }) else { return }
        observers.removeAtIndex(index)
    }
    
	
	func commitUpdateOfPlaybackTime(sender: UISlider) {
        //leave the timer invalidated because changing the value will trigger a notification from the music player
        //causing the view to reload and the timer to be reinitialized
        //this is preferred because we dont want the timer to start until after the seeking to the time has completed
		audioQueuePlayer.currentPlaybackTime = sender.value
		progressSlider.value = sender.value
        updateObservers()
	}
	
	func updateLabelsWithSlider(sender: UISlider) {
		invalidateTimer()
		let sliderValue = sender.value
		let remainingPlaybackTime = sender.maximumValue - sliderValue
		updateLabels(currentPlaybackTime: sliderValue, remainingPlaybackTime: remainingPlaybackTime)
	}
    
    func resetProgressBar() {
		guard UIApplication.sharedApplication().applicationState == UIApplicationState.Active else {
			invalidateTimer()
			return
		}
		
        progressSlider.maximumValue = Float(audioQueuePlayer.nowPlayingItem?.playbackDuration ?? 1.0)
        resetTimer()
        refreshProgressSlider()
    }

	
	func resetTimer() {
		if audioQueuePlayer.musicIsPlaying && playbackProgressTimer == nil {
			KyoozUtils.doInMainQueue() {
				self.playbackProgressTimer = NSTimer.scheduledTimerWithTimeInterval(1.0,
					target: self,
					selector: #selector(self.refreshProgressSlider),
					userInfo: nil,
					repeats: true)
			}
		} else if !audioQueuePlayer.musicIsPlaying && playbackProgressTimer != nil {
			invalidateTimer()
		}
	}
	
	func invalidateTimer() {
		playbackProgressTimer?.invalidate()
		playbackProgressTimer = nil
	}
	
	func refreshProgressSlider() {
		guard audioQueuePlayer.nowPlayingItem != nil else {
			timeRemainingLabel.text = MediaItemUtils.zeroTime
			timeProgressedLabel.text = MediaItemUtils.zeroTime
			progressSlider.setValue(0.0, animated: false)
			return
		}
        
		let currentPlaybackTime = audioQueuePlayer.currentPlaybackTime
		let totalPlaybackTime = progressSlider.maximumValue
		let remainingPlaybackTime = totalPlaybackTime - currentPlaybackTime
		
		updateLabels(currentPlaybackTime:currentPlaybackTime, remainingPlaybackTime:remainingPlaybackTime)
		progressSlider.setValue(currentPlaybackTime, animated: false)
        updateObservers()
	}
    
    
    private func updateObservers() {
        let percentComplete = progressSlider.value/progressSlider.maximumValue
        observers.forEach() { $0.updateProgress(percentComplete) }
    }
    
	private func updateLabels(currentPlaybackTime currentPlaybackTime:Float, remainingPlaybackTime:Float) {
		timeRemainingLabel.text = "-\(MediaItemUtils.getTimeRepresentation(remainingPlaybackTime))"
		timeProgressedLabel.text = MediaItemUtils.getTimeRepresentation(currentPlaybackTime)
	}

    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let application = UIApplication.sharedApplication()
        notificationCenter.addObserver(self, selector: #selector(self.resetProgressBar),
                                       name: AudioQueuePlayerUpdate.NowPlayingItemChanged.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(self.resetProgressBar),
                                       name: AudioQueuePlayerUpdate.PlaybackStateUpdate.rawValue, object: audioQueuePlayer)
        
        notificationCenter.addObserver(self, selector: #selector(self.invalidateTimer),
                                       name: UIApplicationDidEnterBackgroundNotification, object: application)
        notificationCenter.addObserver(self, selector: #selector(self.invalidateTimer),
                                       name: UIApplicationWillResignActiveNotification, object: application)
        notificationCenter.addObserver(self, selector: #selector(self.resetProgressBar),
                                       name: UIApplicationDidBecomeActiveNotification, object: application)
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}
