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
    
    private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    private var labelPageVC:NowPlayingPageViewController!
    private var albumArtPageVC: NowPlayingPageViewController!

    private var observationContext:UInt8 = 123
    private let playbackProgressVC = PlaybackProgressViewController.instance
	private let nowPlayingBarVC = NowPlayingBarViewController()
	private let playbackControlsVC = PlaybackControlsViewController()
    
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
        
        labelPageVC = LabelPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Left, .Right], subView: labelPageVC.view, parentView: view)
        labelPageVC.view.centerYAnchor.constraintEqualToAnchor(nowPlayingBar.centerYAnchor).active = true
        labelPageVC.view.heightAnchor.constraintEqualToAnchor(nowPlayingBar.heightAnchor).active = true

        albumArtPageVC = ImagePageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        
        let albumArtView = albumArtPageVC.view
        albumArtView.layer.shadowOpacity = 0.8
        albumArtView.layer.shadowOffset = CGSize(width: 0, height: 3)
        albumArtView.layer.shadowRadius = 10
        albumArtView.clipsToBounds = false
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Width, .CenterX], subView: albumArtView, parentView: view)
        albumArtView.topAnchor.constraintEqualToAnchor(labelPageVC.view.bottomAnchor, constant: 55).active = true
        albumArtView.heightAnchor.constraintEqualToAnchor(albumArtView.widthAnchor, multiplier: 0.9).active = true
        
        ConstraintUtils.applyConstraintsToView(withAnchors: [.CenterX], subView: playbackProgressVC.view, parentView: view)
        playbackProgressVC.view.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.95).active = true
        playbackProgressVC.view.topAnchor.constraintEqualToAnchor(albumArtView.bottomAnchor, constant: 35).active = true
        playbackProgressVC.view.heightAnchor.constraintEqualToConstant(25).active = true
        addChildViewController(playbackProgressVC)
        playbackProgressVC.didMoveToParentViewController(self)
		
		ConstraintUtils.applyConstraintsToView(withAnchors: [.CenterX], subView: playbackControlsVC.view, parentView: view)

		playbackControlsVC.view.heightAnchor.constraintEqualToConstant(65).active = true
		playbackControlsVC.view.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.9).active = true
		playbackControlsVC.view.topAnchor.constraintEqualToAnchor(playbackProgressVC.view.bottomAnchor, constant: 30).active = true
		addChildViewController(playbackControlsVC)
		playbackControlsVC.didMoveToParentViewController(self)

        KyoozUtils.doInMainQueueAsync() {
            self.reloadData(nil)
            self.updateAlphaLevels()
        }
        view.addObserver(self, forKeyPath: "center", options: .New, context: &observationContext)
    }
	

    func reloadData(notification:NSNotification?) {
        guard UIApplication.sharedApplication().applicationState == UIApplicationState.Active else { return }
        
        func transitionPageVC(pageVC:NowPlayingPageViewController, withVC vc:()->WrapperViewController){
			if !((pageVC.viewControllers?.first as? WrapperViewController)?.isPresentedVC ?? false)
				 || pageVC.refreshNeeded {
				pageVC.refreshNeeded = false
				pageVC.setViewControllers([vc()], direction: .Forward, animated: false, completion: nil)
			}
        }
        
        let nowPlayingItem = audioQueuePlayer.nowPlayingItem
		let index = audioQueuePlayer.indexOfNowPlayingItem
		let labelWrapper = { return LabelStackWrapperViewController(track: nowPlayingItem, isPresentedVC: true, representingIndex: index) }
        transitionPageVC(labelPageVC, withVC: labelWrapper)
		
		let imageWrapper = { return ImageWrapperViewController(track: nowPlayingItem, isPresentedVC: true, representingIndex: index, size: self.albumArtPageVC.view.frame.size) }
        transitionPageVC(albumArtPageVC, withVC: imageWrapper)
        
        KyoozUtils.doInMainQueueAsync() {
            if let image = (self.albumArtPageVC.viewControllers?.first as? ImageWrapperViewController)?.imageView.image?.CGImage {
                self.view.layer.contents = image
            }
        }
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
		let tY = 35 * expandedFraction
		let translationTransform = CATransform3DMakeTranslation(tX, tY, 0)
		
		let scale = 0.8 + (expandedFraction * 0.2)
		let scaleTransform = CATransform3DMakeScale(scale, scale, scale)
		
		labelPageVC.view.layer.transform = CATransform3DConcat(translationTransform, scaleTransform)
    }
	
    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let application = UIApplication.sharedApplication()
        notificationCenter.addObserver(self, selector: #selector(NowPlayingSummaryViewController.reloadData(_:)),
            name: AudioQueuePlayerUpdate.NowPlayingItemChanged.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: #selector(NowPlayingSummaryViewController.reloadData(_:)),
            name: AudioQueuePlayerUpdate.PlaybackStateUpdate.rawValue, object: audioQueuePlayer)
		//this is for refreshing the page views
        notificationCenter.addObserver(self, selector: #selector(NowPlayingSummaryViewController.reloadData(_:)),
            name: AudioQueuePlayerUpdate.QueueUpdate.rawValue, object: audioQueuePlayer)
        
        notificationCenter.addObserver(self, selector: #selector(NowPlayingSummaryViewController.reloadData(_:)),
            name: UIApplicationDidBecomeActiveNotification, object: application)
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}
