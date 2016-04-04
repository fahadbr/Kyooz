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
    var albumArtPageVC: UIPageViewController!

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
    
    private var labelPageVC:UIPageViewController!
	
    typealias KVOContext = UInt8
    private var observationContext = KVOContext()
    
    private var pageVcTransitioning = [UIPageViewController:Bool]()
    
    var expanded:Bool = false {
        didSet{
            albumArtPageVC?.view.hidden = !expanded
        }
    }
	
    
    //MARK: - FUNCTIONS
    deinit {
        Logger.debug("deinitializing NowPlayingSummaryViewController")
        self.invalidateTimer()
        self.unregisterForNotifications()
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
        invalidateTimer()
        let sliderValue = sender.value
        let remainingPlaybackTime = Float(audioQueuePlayer.nowPlayingItem?.playbackDuration ?? 0.0) - sliderValue
        updatePlaybackProgressBarTimeLabels(currentPlaybackTime: sliderValue, remainingPlaybackTime: remainingPlaybackTime)
    }

    @IBAction func skipBackward(sender: AnyObject) {
        audioQueuePlayer.skipBackwards(false)
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
		guard let nowPlayingItem = audioQueuePlayer.nowPlayingItem else {
			return
		}
		
		let kmvc = KyoozMenuViewController()
		kmvc.menuTitle = nowPlayingItem.trackTitle
		kmvc.menuDetails = "\(nowPlayingItem.albumArtist ?? "")  —  \(nowPlayingItem.albumTitle ?? "")"
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
        
        currentPlaybackTimeLabel.font = ThemeHelper.defaultFont?.fontWithSize(10)
        totalPlaybackTimeLabel.font = ThemeHelper.defaultFont?.fontWithSize(10)
        
        registerForNotifications()
        albumArtPageVC = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        albumArtPageVC.dataSource = self
        albumArtPageVC.delegate = self
        
        let albumArtView = albumArtPageVC.view
        albumArtView.layer.shadowOpacity = 0.7
        albumArtView.layer.shadowOffset = CGSize(width: 0, height: 3)
        albumArtView.layer.shadowRadius = 10
        albumArtView.clipsToBounds = false
        view.insertSubview(albumArtView, belowSubview: playbackProgressBar)
        albumArtView.translatesAutoresizingMaskIntoConstraints = false
        albumArtView.bottomAnchor.constraintEqualToAnchor(playbackProgressBar.centerYAnchor).active = true
        albumArtView.widthAnchor.constraintEqualToAnchor(view.widthAnchor).active = true
        albumArtView.heightAnchor.constraintEqualToAnchor(playbackProgressBar.widthAnchor).active = true
        albumArtView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        
        labelPageVC = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Left, .Right], subView: labelPageVC.view, parentView: view)
        labelPageVC.view.centerYAnchor.constraintEqualToAnchor(nowPlayingCollapsedBar.centerYAnchor).active = true
        labelPageVC.view.heightAnchor.constraintEqualToAnchor(nowPlayingCollapsedBar.heightAnchor).active = true
        labelPageVC.dataSource = self
        labelPageVC.delegate = self
        
        KyoozUtils.doInMainQueueAsync() {
            self.reloadData(nil)
            self.updateAlphaLevels()
        }
        self.view.addObserver(self, forKeyPath: "center", options: NSKeyValueObservingOptions.New, context: &self.observationContext)
    }
    
    private func getViewForLabels(track:AudioTrack?) -> UIView {
        func configureLabel(label:UILabel, font:UIFont?) {
            label.textColor = ThemeHelper.defaultFontColor
            label.textAlignment = .Center
            label.font = font
        }
        
        let trackTitleTextView = MarqueeLabel(labelConfigurationBlock: { (label) in
            configureLabel(label, font: UIFont(name: ThemeHelper.defaultFontNameBold, size: 16))
        })
        let trackDetailsTextView = MarqueeLabel(labelConfigurationBlock: { (label) in
            configureLabel(label, font: UIFont(name: ThemeHelper.defaultFontName, size: 14))
        })
        
        let titleText = track?.trackTitle ?? "Nothing"
        let detailsText = "\(track?.albumArtist ?? "To")  —  \(track?.albumTitle ?? "Play")"
        
        trackTitleTextView.text = titleText
        trackDetailsTextView.text = detailsText
        
        let height = trackTitleTextView.intrinsicContentSize().height + trackDetailsTextView.intrinsicContentSize().height
        
        let labelStackView = UIStackView(arrangedSubviews: [trackTitleTextView, trackDetailsTextView])
        labelStackView.axis = .Vertical
        labelStackView.distribution = .FillProportionally
        
        labelStackView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: height)
        
        return labelStackView
    }

    func reloadData(notification:NSNotification?) {
        guard UIApplication.sharedApplication().applicationState == UIApplicationState.Active else { return }
        
        func transitionPageVC(pageVC:UIPageViewController, withVC vc:WrapperViewController) {
            pageVC.setViewControllers([vc], direction: .Forward, animated: false, completion: nil)
//            guard let previousVC = pageVC.viewControllers?.first as? WrapperViewController else {
//                pageVC.setViewControllers([vc], direction: .Forward, animated: false, completion: nil)
//                return
//            }
//            let previousIndex = previousVC.index
//            
//            guard vc.id != previousVC.id else { return }
//            
//            let isTransitioning = pageVcTransitioning[pageVC] ?? false
//            let direction:UIPageViewControllerNavigationDirection = previousIndex > vc.index ? .Reverse : .Forward
//            
//            pageVC.setViewControllers([vc], direction: direction, animated: !isTransitioning, completion: {_ in
//                KyoozUtils.doInMainQueueAsync() {
//                    if !isTransitioning {
//                        pageVC.setViewControllers([vc], direction: direction, animated: false, completion: nil)
//                    }
//                    self.pageVcTransitioning[pageVC] = false
//                }
//            })
//            //if an animation has started (which is only when isTransitioning is false) then we want to make sure that no other animations start
//            //while it is occurring
//            if !isTransitioning {
//                pageVcTransitioning[pageVC] = true
//            }
        }
        
        let nowPlayingItem = audioQueuePlayer.nowPlayingItem;
		let persistentId = nowPlayingItem?.id ?? 0
        let labelView = getViewForLabels(nowPlayingItem)
        let labelWrapper = WrapperViewController(wrappedView: labelView, frameInset: 0, resizeView: false, index: audioQueuePlayer.indexOfNowPlayingItem, id:persistentId)
        transitionPageVC(labelPageVC, withVC: labelWrapper)

        let albumArtId:UInt64 = nowPlayingItem?.artwork == nil ? 0 : nowPlayingItem!.albumId
    
        let imageView = getAlbumArtForTrack(nowPlayingItem)
        let imageWrapper = WrapperViewController(wrappedView: imageView, frameInset: 0, resizeView: true, index: audioQueuePlayer.indexOfNowPlayingItem, id: persistentId)
        transitionPageVC(albumArtPageVC, withVC: imageWrapper)

        self.view.layer.contents = imageView.image?.CGImage
        self.albumIdForCurrentAlbumArt = albumArtId
        
        self.playbackProgressBar.maximumValue = Float(nowPlayingItem?.playbackDuration ?? 1.0)
        
        repeatButton.repeatState = audioQueuePlayer.repeatMode
        shuffleButton.isActive = audioQueuePlayer.shuffleActive
        
        updatePlaybackProgressBar(nil)
        updatePlaybackProgressTimer()
        updatePlaybackStatus(nil)
    }
    
    private func getAlbumArtForTrack(track:AudioTrack?) -> UIImageView {
        let albumArtImage = track?.artwork?.imageWithSize(albumArtPageVC.view.frame.size) ?? ImageContainer.defaultAlbumArtworkImage
        
        let imageView = UIImageView(image: albumArtImage)
        imageView.contentMode = .ScaleAspectFit
        return imageView
    }
    
    @IBAction func updatePlaybackProgressTimer() {
        if(audioQueuePlayer.musicIsPlaying && playbackProgressTimer == nil) {
            Logger.debug("initiating playbackProgressTimer")
            KyoozUtils.doInMainQueue() {
                self.playbackProgressTimer = NSTimer.scheduledTimerWithTimeInterval(1.0,
                    target: self,
                    selector: #selector(NowPlayingSummaryViewController.updatePlaybackProgressBar(_:)),
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
            totalPlaybackTimeLabel.text = MediaItemUtils.zeroTime
            currentPlaybackTimeLabel.text = MediaItemUtils.zeroTime
            playbackProgressBar.setValue(0.0, animated: false)
            playbackProgressCollapsedBar.progress = 0.0
            return
        }
        let currentPlaybackTime = audioQueuePlayer.currentPlaybackTime
        let totalPlaybackTime = Float(audioQueuePlayer.nowPlayingItem!.playbackDuration)
        let remainingPlaybackTime = totalPlaybackTime - currentPlaybackTime
        
        updatePlaybackProgressBarTimeLabels(currentPlaybackTime:currentPlaybackTime, remainingPlaybackTime:remainingPlaybackTime)
        let progress = currentPlaybackTime
        playbackProgressBar.setValue(progress, animated: true)
        playbackProgressCollapsedBar.setProgress(Float(progress/totalPlaybackTime), animated: true)
    }
    
    func updatePlaybackProgressBarTimeLabels(currentPlaybackTime currentPlaybackTime:Float, remainingPlaybackTime:Float) {
        totalPlaybackTimeLabel.text = "-" + MediaItemUtils.getTimeRepresentation(remainingPlaybackTime)
        currentPlaybackTimeLabel.text = MediaItemUtils.getTimeRepresentation(currentPlaybackTime)
    }
    
    func updatePlaybackStatus(sender:AnyObject?) {
        let musicIsNotPlaying = !audioQueuePlayer.musicIsPlaying
        playPauseButton.isPlayButton = musicIsNotPlaying
        playPauseCollapsedButton.isPlayButton = musicIsNotPlaying
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
        if expandedFraction > 0 && albumArtPageVC.view.hidden {
            albumArtPageVC.view.hidden = false
        }
        
        albumArtPageVC.view.alpha = expandedFraction
		nowPlayingCollapsedBar.alpha = collapsedFraction
				
		let tX = (labelPageVC.view.center.x - nowPlayingCollapsedBar.bounds.midX) * -expandedFraction
		let tY = 30 * expandedFraction
		let translationTransform = CATransform3DMakeTranslation(tX, tY, 0)
		
		let scale = 0.8 + (expandedFraction * 0.2)
		let scaleTransform = CATransform3DMakeScale(scale, scale, scale)
		
		labelPageVC.view.layer.transform = CATransform3DConcat(translationTransform, scaleTransform)
    }
	
	private func executeBlockInTransitionAnimation(view:UIView, delay:Double, block:()->()) {
		if expanded || view !== albumArtPageVC {
			let transition:UIViewAnimationOptions = view === albumArtPageVC ? .TransitionCrossDissolve : .TransitionFlipFromBottom
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
        notificationCenter.addObserver(self, selector: #selector(NowPlayingSummaryViewController.reloadData(_:)),
            name: AudioQueuePlayerUpdate.QueueUpdate.rawValue, object: audioQueuePlayer)
        
        notificationCenter.addObserver(self, selector: #selector(NowPlayingSummaryViewController.invalidateTimer),
            name: UIApplicationDidEnterBackgroundNotification, object: application)
        notificationCenter.addObserver(self, selector: #selector(NowPlayingSummaryViewController.invalidateTimer),
            name: UIApplicationWillResignActiveNotification, object: application)
        notificationCenter.addObserver(self, selector: #selector(NowPlayingSummaryViewController.reloadData(_:)),
            name: UIApplicationDidBecomeActiveNotification, object: application)
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}

extension NowPlayingSummaryViewController : UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    private func wrapperVCForIndex(pageVC:UIPageViewController, index:Int) -> WrapperViewController? {
        let queue = audioQueuePlayer.nowPlayingQueue
        guard index >= 0 && !queue.isEmpty && index < queue.count else {
            return nil
        }
        let track = queue[index]
        let isLabelVc = pageVC === labelPageVC
        let view = isLabelVc ? getViewForLabels(track) : getAlbumArtForTrack(track)
        let wrapperVC = WrapperViewController(wrappedView: view, frameInset: 0 , resizeView: !isLabelVc, index: index, id: track.id)
        return wrapperVC
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let wrapperVC = wrapperVCForIndex(pageViewController, index:audioQueuePlayer.indexOfNowPlayingItem + 1)
        wrapperVC?.completionBlock = { [audioQueuePlayer = self.audioQueuePlayer] in
            audioQueuePlayer.skipForwards()
        }
        return wrapperVC
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let wrapperVC = wrapperVCForIndex(pageViewController, index:audioQueuePlayer.indexOfNowPlayingItem - 1)
        wrapperVC?.completionBlock = { [audioQueuePlayer = self.audioQueuePlayer] in
            audioQueuePlayer.skipBackwards(true)
        }
        return wrapperVC
    }
    
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        pageVcTransitioning[pageViewController] = true
    }
    
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            (pageViewController.viewControllers?.first as? WrapperViewController)?.completionBlock?()
        }
        pageVcTransitioning[pageViewController] = false
    }
}

