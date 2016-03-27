//
//  NowPlayingSummaryViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 4/11/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class NowPlayingSummaryViewController: UIViewController {
    //MARK: - PROPERTIES
    @IBOutlet var albumArtwork: UIImageView!
	@IBOutlet var labelStackView: UIStackView!

    @IBOutlet var songTitleCollapsedLabel: UILabel!
    @IBOutlet var albumArtistAndAlbumTitleCollapsedLabel: UILabel!
	@IBOutlet var menuButtonView: MenuDotsView!
    
    @IBOutlet var playbackProgressBar: UISlider!
    @IBOutlet var totalPlaybackTimeLabel: UILabel!
    @IBOutlet var currentPlaybackTimeLabel: UILabel!
    
    @IBOutlet var playPauseButton: PlayPauseButtonView!
    @IBOutlet var playPauseCollapsedButton: PlayPauseButtonView!
    
    @IBOutlet var nowPlayingCollapsedBar: UIView!
    @IBOutlet var playbackProgressCollapsedBar: UIProgressView!
    
    @IBOutlet var repeatButton: RepeatButtonView!
    @IBOutlet var shuffleButton: ShuffleButtonView!
    
    private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    private let timeDelayInNanoSeconds = Int64(0.5 * Double(NSEC_PER_SEC))
    
    private var playbackProgressTimer:NSTimer?
    private var albumIdForCurrentAlbumArt:UInt64?
	
    typealias KVOContext = UInt8
    private var observationContext = KVOContext()
    
    var expanded:Bool = false {
        didSet{
            albumArtwork?.hidden = !expanded
        }
    }
	
    
    //MARK: - FUNCTIONS
    deinit {
        Logger.debug("deinitializing NowPlayingSummaryViewController")
        self.invalidateTimer(nil)
        self.unregisterForNotifications()
    }
    
    @IBAction func newPlayButtonPressed(sender: AnyObject) {
        Logger.debug("play button pressed")
    }

    
    @IBAction func commitUpdateOfPlaybackTime(sender: UISlider) {
        audioQueuePlayer.currentPlaybackTime = sender.value
        playbackProgressBar.value = sender.value
        playbackProgressCollapsedBar.progress = sender.value
        //leave the timer invalidated because changing the value will trigger a notification from the music player
        //causing the view to reload and the timer to be reinitialized
        //this is preferred because we dont want the timer to start until after the seeking to the time has completed
    }

    @IBAction func updatePlaybackTime(sender: UISlider, forEvent event: UIEvent) {
        invalidateTimer(sender)
        let sliderValue = sender.value
        let remainingPlaybackTime = Float(audioQueuePlayer.nowPlayingItem?.playbackDuration ?? 0.0) - sliderValue
        updatePlaybackProgressBarTimeLabels(currentPlaybackTime: sliderValue, remainingPlaybackTime: remainingPlaybackTime)
    }

    
    @IBAction func skipBackward(sender: AnyObject) {
        audioQueuePlayer.skipBackwards()
        updatePlaybackProgressBar(nil)
    }
    @IBAction func skipForward(sender: AnyObject) {
        audioQueuePlayer.skipForwards()
    }
    
    
    @IBAction func playPauseAction(sender: AnyObject) {
        if(audioQueuePlayer.musicIsPlaying) {
            self.audioQueuePlayer.pause()
        } else {
            self.audioQueuePlayer.play()
        }
    }
    
    @IBAction func toggleShuffle(sender: AnyObject) {
        let newState = !audioQueuePlayer.shuffleActive
        audioQueuePlayer.shuffleActive = newState
        shuffleButton.isActive = audioQueuePlayer.shuffleActive
    }
    
    @IBAction func switchRepeatMode(sender: AnyObject) {
        let newState = audioQueuePlayer.repeatMode.nextState
        audioQueuePlayer.repeatMode = newState
        repeatButton.repeatState = audioQueuePlayer.repeatMode
    }
    
    @IBAction func showQueue(sender: AnyObject) {
        ContainerViewController.instance.toggleSidePanel()
    }
    
    
    @IBAction func goToArtist(sender: AnyObject) {
        goToVCWithGrouping(LibraryGrouping.Artists)
    }
    @IBAction func goToAlbum(sender: AnyObject) {
        goToVCWithGrouping(LibraryGrouping.Albums)
    }
	
	@IBAction func menuButtonPressed(sender: AnyObject) {
		guard audioQueuePlayer.nowPlayingItem != nil else {
			return
		}
		
		let kmvc = KyoozMenuViewController()
		kmvc.menuTitle = songTitleCollapsedLabel.text
		kmvc.menuDetails = albumArtistAndAlbumTitleCollapsedLabel.text
		let center = menuButtonView.superview?.convertPoint(menuButtonView.center, toCoordinateSpace: UIScreen.mainScreen().coordinateSpace)
		kmvc.originatingCenter = center
		
		kmvc.addAction(KyoozMenuAction(title: "Jump To Album", image: nil) {
			self.goToVCWithGrouping(LibraryGrouping.Albums)
		})
		kmvc.addAction(KyoozMenuAction(title: "Jump To Artist", image: nil) {
			self.goToVCWithGrouping(LibraryGrouping.Artists)
		})
		kmvc.addAction(KyoozMenuAction(title: "Cancel", image: nil, action: nil))
		KyoozUtils.showMenuViewController(kmvc)
	}
    
    private func goToVCWithGrouping(libraryGrouping:LibraryGrouping) {
        if let nowPlayingItem = audioQueuePlayer.nowPlayingItem, let sourceData = MediaQuerySourceData(filterEntity: nowPlayingItem, parentLibraryGroup: libraryGrouping, baseQuery: nil) {
            ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(sourceData, parentGroup: libraryGrouping, entity: nowPlayingItem)
        }
    }
    
    @IBAction func collapseViewController(sender: AnyObject) {
        RootViewController.instance.animatePullablePanel(shouldExpand: false)
    }
    
    //MARK: - FUNCTIONS: - Overridden functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reloadData(nil)
        registerForNotifications()
        
        albumArtwork.layer.shadowOpacity = 0.7
        albumArtwork.layer.shadowOffset = CGSize(width: 0, height: 3)
        albumArtwork.layer.shadowRadius = 10
        updateAlphaLevels()
        self.view.addObserver(self, forKeyPath: "center", options: NSKeyValueObservingOptions.New, context: &self.observationContext)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        invalidateTimer(nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        invalidateTimer(nil)
    }
    
    func reloadData(notification:NSNotification?) {
        if(UIApplication.sharedApplication().applicationState != UIApplicationState.Active) { return }
        
        let nowPlayingItem = audioQueuePlayer.nowPlayingItem;
		
//		let titleText = nowPlayingItem?.trackTitle ?? "Nothing"
		let titleText = "this is going to be some really long text to fill up the label"
		updateLabel(true, label: songTitleCollapsedLabel, withText: titleText, delay: 0)
		
//		let detailsText = "\(nowPlayingItem?.albumArtist ?? "To") - \(nowPlayingItem?.albumTitle ?? "Play")"
		let detailsText = "more really long text to fill up the width of the screen"
		updateLabel(true, label: albumArtistAndAlbumTitleCollapsedLabel, withText: detailsText, delay: 0.2)

        let artwork = nowPlayingItem?.artwork
        let albumArtId:UInt64
        if(artwork == nil) {
            albumArtId = 0
        } else {
            albumArtId = nowPlayingItem!.albumId
        }
        
        if(albumIdForCurrentAlbumArt == nil || albumIdForCurrentAlbumArt! != albumArtId) {
            Logger.debug("loading new album art image")
            let albumArtImage = artwork?.imageWithSize(albumArtwork.frame.size) ?? ImageContainer.defaultAlbumArtworkImage
			executeBlockInTransitionAnimation(false, view: albumArtwork, delay: 0) {
				self.albumArtwork.image = albumArtImage
			}

			self.view.layer.contents = albumArtImage.CGImage
            self.albumIdForCurrentAlbumArt = albumArtId
        }
        
        self.playbackProgressBar.maximumValue = Float(nowPlayingItem?.playbackDuration ?? 1.0)
        
        repeatButton.repeatState = audioQueuePlayer.repeatMode
        shuffleButton.isActive = audioQueuePlayer.shuffleActive
        
        updatePlaybackProgressBar(nil)
        updatePlaybackProgressTimer()
        updatePlaybackStatus(nil)
    }
    
    @IBAction func updatePlaybackProgressTimer() {
        if(audioQueuePlayer.musicIsPlaying && playbackProgressTimer == nil) {
            Logger.debug("initiating playbackProgressTimer")
            playbackProgressTimer = NSTimer.scheduledTimerWithTimeInterval(1.0,
                target: self,
                selector: #selector(NowPlayingSummaryViewController.updatePlaybackProgressBar(_:)),
                userInfo: nil,
                repeats: true)
        } else if(!audioQueuePlayer.musicIsPlaying && playbackProgressTimer != nil){
            invalidateTimer(nil)
        }
    }
    
    func invalidateTimer(sender:AnyObject?) {
        if let uwTimer = self.playbackProgressTimer {
            Logger.debug("resetting playbackProgressTimer")
            uwTimer.invalidate()
            self.playbackProgressTimer = nil
        }

    }
    
    func updatePlaybackProgressBar(sender:NSTimer?) {
        dispatch_async(dispatch_get_main_queue(), { [unowned self]() in
            if(self.audioQueuePlayer.nowPlayingItem == nil) {
                self.totalPlaybackTimeLabel.text = MediaItemUtils.zeroTime
                self.currentPlaybackTimeLabel.text = MediaItemUtils.zeroTime
                self.playbackProgressBar.setValue(0.0, animated: false)
                self.playbackProgressCollapsedBar.progress = 0.0
                return
            }
            let currentPlaybackTime = self.audioQueuePlayer.currentPlaybackTime
            let totalPlaybackTime = Float(self.audioQueuePlayer.nowPlayingItem!.playbackDuration)
            let remainingPlaybackTime = totalPlaybackTime - currentPlaybackTime
            
            self.updatePlaybackProgressBarTimeLabels(currentPlaybackTime:currentPlaybackTime, remainingPlaybackTime:remainingPlaybackTime)
            let progress = currentPlaybackTime
            self.playbackProgressBar.setValue(progress, animated: true)
            self.playbackProgressCollapsedBar.setProgress(Float(progress/totalPlaybackTime), animated: true)
        })
    }
    
    func updatePlaybackProgressBarTimeLabels(currentPlaybackTime currentPlaybackTime:Float, remainingPlaybackTime:Float) {
        totalPlaybackTimeLabel.text = "-" + MediaItemUtils.getTimeRepresentation(remainingPlaybackTime)
        currentPlaybackTimeLabel.text = MediaItemUtils.getTimeRepresentation(currentPlaybackTime)
    }
    
    func updatePlaybackStatus(sender:AnyObject?) {
        if(audioQueuePlayer.musicIsPlaying) {
            playPauseButton.isPlayButton = false
            playPauseCollapsedButton.isPlayButton = false
        } else {
            playPauseButton.isPlayButton = true
            playPauseCollapsedButton.isPlayButton = true
        }
    }
    
    //MARK: - FUNCTIONS: - KVOFunction
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		if keyPath != nil && keyPath == "center" {
            updateAlphaLevels()
		} else {
            Logger.error("non observed property has changed")
        }
    }
    
    //MARK: - FUNCTIONS: - Private Functions
    
    private func updateAlphaLevels() {
        let frame = self.view.frame
        let maxY = frame.height - RootViewController.nowPlayingViewCollapsedOffset
        let currentY = maxY - (frame.origin.y - RootViewController.nowPlayingViewCollapsedOffset)
        var expandedFraction = (currentY/maxY)
        
        if(expandedFraction > 1.0 || expandedFraction < 0.1) {
            expandedFraction = floor(expandedFraction)
        }
        let collapsedFraction = 1 - expandedFraction
        if expandedFraction > 0 && albumArtwork.hidden {
            albumArtwork.hidden = false
        }
        
        albumArtwork.alpha = expandedFraction
		nowPlayingCollapsedBar.alpha = 1.0
        playPauseCollapsedButton.alpha = collapsedFraction
		menuButtonView.alpha = collapsedFraction
		
		
		let tX = (labelStackView.center.x - nowPlayingCollapsedBar.bounds.midX) * -expandedFraction
		let tY = 30 * expandedFraction
		let translationTransform = CATransform3DMakeTranslation(tX, tY, 0)
		
		let scale = 0.7 + (expandedFraction * 0.3)
		let scaleTransform = CATransform3DMakeScale(scale, scale, scale)
		
		labelStackView.layer.transform = CATransform3DConcat(translationTransform, scaleTransform)
    }
	
	private func updateLabel(forCollapsedBar:Bool, label:UILabel, withText newText:String, delay:Double) {
		if label.text == nil || label.text! != newText {
			executeBlockInTransitionAnimation(forCollapsedBar, view: label, delay: delay) {
				label.text = newText
			}
		}
	}
	
	private func executeBlockInTransitionAnimation(forCollapsedBar:Bool, view:UIView, delay:Double, block:()->()) {
		if (forCollapsedBar && !expanded) || (!forCollapsedBar && expanded) {
			let transition:UIViewAnimationOptions = view === albumArtwork ? .TransitionCrossDissolve : .TransitionFlipFromBottom
			dispatch_after(KyoozUtils.getDispatchTimeForSeconds(delay), dispatch_get_main_queue()) {
				UIView.transitionWithView(view, duration: 0.5, options: transition, animations: block, completion: nil)
			}
		} else {
			block()
		}
	}


    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let application = UIApplication.sharedApplication()
        notificationCenter.addObserver(self, selector: #selector(NowPlayingSummaryViewController.reloadData(_:)),
            name: AudioQueuePlayerUpdate.NowPlayingItemChanged.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(NowPlayingSummaryViewController.reloadData(_:)),
            name: AudioQueuePlayerUpdate.PlaybackStateUpdate.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(NowPlayingSummaryViewController.reloadData(_:)),
            name: AudioQueuePlayerUpdate.SystematicQueueUpdate.rawValue, object: audioQueuePlayer)
        
        notificationCenter.addObserver(self, selector: #selector(NowPlayingSummaryViewController.invalidateTimer(_:)),
            name: UIApplicationDidEnterBackgroundNotification, object: application)
        notificationCenter.addObserver(self, selector: #selector(NowPlayingSummaryViewController.invalidateTimer(_:)),
            name: UIApplicationWillResignActiveNotification, object: application)
        notificationCenter.addObserver(self, selector: #selector(NowPlayingSummaryViewController.reloadData(_:)),
            name: UIApplicationDidBecomeActiveNotification, object: application)
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}

