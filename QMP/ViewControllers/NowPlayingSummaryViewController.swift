//
//  NowPlayingSummaryViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 4/11/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class NowPlayingSummaryViewController: UIViewController {
    //MARK: - PROPERTIES
	
	static let CollapsedHeight:CGFloat = 45
    
    @IBOutlet var playPauseButton: PlayPauseButtonView!
    @IBOutlet var repeatButton: RepeatButtonView!
    @IBOutlet var shuffleButton: ShuffleButtonView!
    
    private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    private var labelPageVC:UIPageViewController!
    private var albumArtPageVC: UIPageViewController!

    private var observationContext:UInt8 = 123
    private let playbackProgressVC = PlaybackProgressViewController.instance
	private let nowPlayingBarVC = NowPlayingBarViewController()
    
    var expanded:Bool = false {
        didSet{
            albumArtPageVC?.view.hidden = !expanded
        }
    }
	
    
    //MARK: - FUNCTIONS
    deinit {
        Logger.debug("deinitializing NowPlayingSummaryViewController")
        self.unregisterForNotifications()
    }

    @IBAction func skipBackward(sender: AnyObject) {
        audioQueuePlayer.skipBackwards(false)
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
        view.contentMode = .ScaleAspectFill
        view.clipsToBounds = true
        registerForNotifications()
		
		let nowPlayingBar = nowPlayingBarVC.view
		ConstraintUtils.applyConstraintsToView(withAnchors: [.Left, .Top, .Right], subView: nowPlayingBar, parentView: view)
		nowPlayingBar.heightAnchor.constraintEqualToConstant(self.dynamicType.CollapsedHeight).active = true
        
        labelPageVC = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        labelPageVC.dataSource = self
        labelPageVC.delegate = self
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Left, .Right], subView: labelPageVC.view, parentView: view)
        labelPageVC.view.centerYAnchor.constraintEqualToAnchor(nowPlayingBar.centerYAnchor).active = true
        labelPageVC.view.heightAnchor.constraintEqualToAnchor(nowPlayingBar.heightAnchor).active = true

        
        
        albumArtPageVC = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        albumArtPageVC.dataSource = self
        albumArtPageVC.delegate = self
        
        let albumArtView = albumArtPageVC.view
        albumArtView.layer.shadowOpacity = 0.8
        albumArtView.layer.shadowOffset = CGSize(width: 0, height: 3)
        albumArtView.layer.shadowRadius = 10
        albumArtView.clipsToBounds = false
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Width, .CenterX], subView: albumArtView, parentView: view)
        albumArtView.topAnchor.constraintEqualToAnchor(labelPageVC.view.bottomAnchor, constant: 35).active = true
        albumArtView.heightAnchor.constraintEqualToAnchor(albumArtView.widthAnchor, multiplier: 0.9).active = true
        
        ConstraintUtils.applyConstraintsToView(withAnchors: [.CenterX], subView: playbackProgressVC.view, parentView: view)
        playbackProgressVC.view.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.95).active = true
        playbackProgressVC.view.topAnchor.constraintEqualToAnchor(albumArtView.bottomAnchor, constant: 35).active = true
        playbackProgressVC.view.heightAnchor.constraintEqualToConstant(25).active = true
        addChildViewController(playbackProgressVC)
        playbackProgressVC.didMoveToParentViewController(self)
        

        KyoozUtils.doInMainQueueAsync() {
            self.reloadData(nil)
            self.updateAlphaLevels()
        }
        view.addObserver(self, forKeyPath: "center", options: .New, context: &observationContext)
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
        }
        
        let nowPlayingItem = audioQueuePlayer.nowPlayingItem;
		let persistentId = nowPlayingItem?.id ?? 0
        let labelView = getViewForLabels(nowPlayingItem)
        let labelWrapper = WrapperViewController(wrappedView: labelView, frameInset: 0, resizeView: false, index: audioQueuePlayer.indexOfNowPlayingItem, id:persistentId)
        transitionPageVC(labelPageVC, withVC: labelWrapper)
    
        let imageView = getAlbumArtForTrack(nowPlayingItem)
        let imageWrapper = WrapperViewController(wrappedView: imageView, frameInset: 0, resizeView: true, index: audioQueuePlayer.indexOfNowPlayingItem, id: persistentId)
        transitionPageVC(albumArtPageVC, withVC: imageWrapper)

        self.view.layer.contents = imageView.image?.CGImage
        
        repeatButton.repeatState = audioQueuePlayer.repeatMode
        shuffleButton.isActive = audioQueuePlayer.shuffleActive

        updatePlaybackStatus(nil)
    }
    
    private func getAlbumArtForTrack(track:AudioTrack?) -> UIImageView {
        let albumArtImage = track?.artwork?.imageWithSize(albumArtPageVC.view.frame.size) ?? ImageContainer.defaultAlbumArtworkImage
        
        let imageView = UIImageView(image: albumArtImage)
        imageView.contentMode = .ScaleAspectFit
        return imageView
    }

    
    func updatePlaybackStatus(sender:AnyObject?) {
        let musicIsNotPlaying = !audioQueuePlayer.musicIsPlaying
        playPauseButton.isPlayButton = musicIsNotPlaying
    }
    
    //MARK: - FUNCTIONS: - KVOFunction
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard keyPath != nil else { return }
		if keyPath == "center"{
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
		nowPlayingBarVC.view.alpha = collapsedFraction
				
		let tX = (labelPageVC.view.center.x - nowPlayingBarVC.view.bounds.midX) * -expandedFraction
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
    
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            (pageViewController.viewControllers?.first as? WrapperViewController)?.completionBlock?()
        }
    }
}

