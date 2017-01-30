//
//  PlaybackProgressViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/4/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

protocol PlaybackProgressObserver : class {
    func updateProgress(_ percentComplete:Float)
}

final class PlaybackProgressViewController: UIViewController {
	
	static let instance = PlaybackProgressViewController()
	
	private let progressSlider = UISlider()
	private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
	
	private let timeProgressedLabel = UILabel()
	private let timeRemainingLabel = UILabel()
	
	private var playbackProgressTimer:Timer?
    private var observers = [PlaybackProgressObserver]()

    override func viewDidLoad() {
        super.viewDidLoad()

		func configureLabel(_ label:UILabel) {
			label.font = ThemeHelper.defaultFont?.withSize(ThemeHelper.smallFontSize - 1)
			label.textColor = ThemeHelper.defaultFontColor
            label.textAlignment = .center
			label.text = "000:00"
            label.alpha = 0.6
            label.frame.size = label.textRect(forBounds: UIScreen.main.bounds, limitedToNumberOfLines: 1).size
            
            view.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.heightAnchor.constraint(equalToConstant: label.frame.height).isActive = true
            label.widthAnchor.constraint(equalToConstant: label.frame.width).isActive = true
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
		}
		
        let margin:CGFloat = 4
        configureLabel(timeProgressedLabel)
        timeProgressedLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: margin).isActive = true
        configureLabel(timeRemainingLabel)
        timeRemainingLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -margin).isActive = true
        
        view.addSubview(progressSlider)
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.leftAnchor.constraint(equalTo: timeProgressedLabel.rightAnchor, constant: margin).isActive = true
        progressSlider.rightAnchor.constraint(equalTo: timeRemainingLabel.leftAnchor, constant: -margin).isActive = true
        progressSlider.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        let trackAlpha:CGFloat = 0.4
//        progressSlider.maximumTrackTintColor = UIColor(white: 0.8, alpha: trackAlpha)
		progressSlider.minimumTrackTintColor = ThemeHelper.defaultVividColor
        progressSlider.maximumTrackTintColor = UIColor(white: 0, alpha: trackAlpha)
		progressSlider.accessibilityLabel = "playbackProgressSlider"

        let thumbView = UIView(frame: CGRect(x: 0, y: 0, width: 7, height: 20))
        thumbView.backgroundColor = UIColor.lightGray
        thumbView.layer.cornerRadius = 2
        thumbView.layer.masksToBounds = true
        let thumbImage = ImageUtils.imageForView(thumbView, opaque: false)
        progressSlider.setThumbImage(thumbImage, for: UIControlState())
        progressSlider.setThumbImage(thumbImage, for: .selected)
        progressSlider.setThumbImage(thumbImage, for: .highlighted)

		progressSlider.addTarget(self, action: #selector(self.resetTimer), for: .touchCancel)
		progressSlider.addTarget(self, action: #selector(self.updateLabelsWithSlider(_:)), for: .valueChanged)
		let touchUpEvents = UIControlEvents.touchUpOutside.union(.touchUpInside)
		progressSlider.addTarget(self, action: #selector(self.commitUpdateOfPlaybackTime(_:)), for: touchUpEvents)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resetTimer()
        registerForNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        invalidateTimer()
        unregisterForNotifications()
    }
    
    func addProgressObserver(_ observer:PlaybackProgressObserver) {
        guard !observers.contains(where: { $0 === observer }) else { return }
        observers.append(observer)
    }
    
    func removeProgressObserver(_ observer:PlaybackProgressObserver) {
        guard let index = observers.index( where: { $0 === observer }) else { return }
        observers.remove(at: index)
    }
    
	
	func commitUpdateOfPlaybackTime(_ sender: UISlider) {
        //leave the timer invalidated because changing the value will trigger a notification from the music player
        //causing the view to reload and the timer to be reinitialized
        //this is preferred because we dont want the timer to start until after the seeking to the time has completed
		audioQueuePlayer.currentPlaybackTime = sender.value
		progressSlider.value = sender.value
        updateObservers()
	}
	
	func updateLabelsWithSlider(_ sender: UISlider) {
		invalidateTimer()
		let sliderValue = sender.value
		let remainingPlaybackTime = sender.maximumValue - sliderValue
		updateLabels(currentPlaybackTime: sliderValue, remainingPlaybackTime: remainingPlaybackTime)
	}
    
    func resetProgressBar() {
		guard UIApplication.shared.applicationState == UIApplicationState.active else {
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
				self.playbackProgressTimer = Timer.scheduledTimer(timeInterval: 1.0,
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
    
	private func updateLabels(currentPlaybackTime:Float, remainingPlaybackTime:Float) {
		timeRemainingLabel.text = "-\(MediaItemUtils.getTimeRepresentation(remainingPlaybackTime))"
		timeProgressedLabel.text = MediaItemUtils.getTimeRepresentation(currentPlaybackTime)
	}

    private func registerForNotifications() {
        let notificationCenter = NotificationCenter.default
        let application = UIApplication.shared
        notificationCenter.addObserver(self, selector: #selector(self.resetProgressBar),
                                       name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.nowPlayingItemChanged.rawValue), object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(self.resetProgressBar),
                                       name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.playbackStateUpdate.rawValue), object: audioQueuePlayer)
        
        notificationCenter.addObserver(self, selector: #selector(self.invalidateTimer),
                                       name: NSNotification.Name.UIApplicationDidEnterBackground, object: application)
        notificationCenter.addObserver(self, selector: #selector(self.invalidateTimer),
                                       name: NSNotification.Name.UIApplicationWillResignActive, object: application)
        notificationCenter.addObserver(self, selector: #selector(self.resetProgressBar),
                                       name: NSNotification.Name.UIApplicationDidBecomeActive, object: application)
    }
    
    private func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

}
