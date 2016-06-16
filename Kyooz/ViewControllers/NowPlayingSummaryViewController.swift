//
//  NowPlayingSummaryViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 4/11/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

private let bottomButtonHeight:CGFloat = 30

final class NowPlayingSummaryViewController: UIViewController {
    //MARK: - PROPERTIES
	
	static let CollapsedHeight:CGFloat = 45
	static let heightScale:CGFloat = max(UIScreen.mainScreen().bounds.height, UIScreen.mainScreen().bounds.width)/667
    
    private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
//    private let labelPageVC:NowPlayingPageViewController = LabelPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
    private let albumArtPageVC: NowPlayingPageViewController = ImagePageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
    private var collapseButton:UIButton!
    
    private let playbackProgressVC = PlaybackProgressViewController.instance
	private let nowPlayingBarVC = NowPlayingBarViewController()
	private let playbackControlsVC = PlaybackControlsViewController()
    private lazy var labelWrapperVC:LabelStackWrapperViewController = {
        let track = self.audioQueuePlayer.nowPlayingItem
        let index = self.audioQueuePlayer.indexOfNowPlayingItem
        let vc = LabelStackWrapperViewController(track: track,
                                                 isPresentedVC: true,
                                                 representingIndex: index,
                                                 useSmallFont: self.dynamicType.heightScale < 0.8)
        return vc
    }()
    
    
    private let gradiantLayer:CAGradientLayer = {
        let gradiant = CAGradientLayer()
        gradiant.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradiant.endPoint = CGPoint(x: 0.5, y: 0)
        gradiant.colors = [ThemeHelper.defaultTableCellColor.CGColor, UIColor.clearColor().CGColor, UIColor.clearColor().CGColor, ThemeHelper.defaultTableCellColor.CGColor]
        gradiant.locations = [0.0,0.25,0.75,1.0]
        return gradiant
    }()
    
    private var observationContext:UInt8 = 123
    
    var expanded:Bool = false {
        didSet{
            UIView.animateWithDuration(0.5) { 
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
	
    //MARK: - FUNCTIONS
    deinit {
        Logger.debug("deinitializing NowPlayingSummaryViewController")
        self.unregisterForNotifications()
    }

    
    func goToArtist(sender: AnyObject) {
        goToVCWithGrouping(LibraryGrouping.Artists)
    }
    
    func goToAlbum(sender: AnyObject) {
        goToVCWithGrouping(LibraryGrouping.Albums)
    }
    
    func addToPlaylist(sender: AnyObject) {
        guard let nowPlayingItem = audioQueuePlayer.nowPlayingItem else { return }
        KyoozUtils.showAvailablePlaylistsForAddingTracks([nowPlayingItem])
    }
	
    private func goToVCWithGrouping(libraryGrouping:LibraryGrouping) {
        if let nowPlayingItem = audioQueuePlayer.nowPlayingItem, let sourceData = MediaQuerySourceData(filterEntity: nowPlayingItem, parentLibraryGroup: libraryGrouping, baseQuery: nil) {
            ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(sourceData, parentGroup: libraryGrouping, entity: nowPlayingItem)
        }
    }
    
    func collapseViewController(sender: AnyObject) {
        RootViewController.instance.animatePullablePanel(shouldExpand: false)
    }
    
    //MARK: - FUNCTIONS: - Overridden functions
    override func viewDidLoad() {
        super.viewDidLoad()
        view.contentMode = .ScaleAspectFill
        view.clipsToBounds = true
        registerForNotifications()
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        ConstraintUtils.applyStandardConstraintsToView(subView: blurView, parentView: view)
        blurView.contentView.layer.addSublayer(gradiantLayer)
		
		let nowPlayingBar = nowPlayingBarVC.view
		ConstraintUtils.applyConstraintsToView(withAnchors: [.Left, .Top, .Right], subView: nowPlayingBar, parentView: view)
		nowPlayingBar.heightAnchor.constraintEqualToConstant(self.dynamicType.CollapsedHeight).active = true
        addChildViewController(nowPlayingBarVC)
        nowPlayingBarVC.didMoveToParentViewController(self)

        let bottomButtonView = createBottomButtonView()

        
        let mainStackView = UIStackView(arrangedSubviews: [labelWrapperVC.view, albumArtPageVC.view, playbackProgressVC.view, playbackControlsVC.view, bottomButtonView])
        mainStackView.axis = .Vertical
        mainStackView.distribution = .EqualSpacing
        mainStackView.alignment = .Center
        
        
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Left, .Right, .CenterY], subView: mainStackView, parentView: view)
        //the calculation of this constant is based off of how tall the screen is.  for an iPhone 6 with a portrait height of 667
        //the distance from the top of the stack view to the top of the main view should be about the height of the collapsed bar
        //plus the height of the labelPageVC plus a certain margin 45 + (45 + 25) 
		
//        mainStackView.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: 35 * self.dynamicType.heightScale).active = true
//        mainStackView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -5).active = true
        mainStackView.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 0.95).active = true
		
        albumArtPageVC.view.widthAnchor.constraintEqualToAnchor(mainStackView.widthAnchor).active = true
        if (UIScreen.mainScreen().bounds.width * 0.9) > (UIScreen.mainScreen().bounds.height * 0.55) {
            albumArtPageVC.view.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 0.55).active = true
        } else {
            albumArtPageVC.view.heightAnchor.constraintEqualToAnchor(albumArtPageVC.view.widthAnchor, multiplier: 0.9).active = true
        }
        addChildViewController(albumArtPageVC)
        albumArtPageVC.didMoveToParentViewController(self)
        
        labelWrapperVC.view.heightAnchor.constraintEqualToAnchor(nowPlayingBar.heightAnchor).active = true
        labelWrapperVC.view.widthAnchor.constraintEqualToAnchor(mainStackView.widthAnchor, multiplier: 0.95).active = true
        addChildViewController(labelWrapperVC)
        labelWrapperVC.didMoveToParentViewController(self)

        playbackProgressVC.view.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.95).active = true
        playbackProgressVC.view.heightAnchor.constraintEqualToConstant(25).active = true
        addChildViewController(playbackProgressVC)
        playbackProgressVC.didMoveToParentViewController(self)
        
        playbackControlsVC.view.heightAnchor.constraintEqualToConstant(50).active = true
        playbackControlsVC.view.widthAnchor.constraintEqualToAnchor(mainStackView.widthAnchor, multiplier: 0.9).active = true
        addChildViewController(playbackControlsVC)
        playbackControlsVC.didMoveToParentViewController(self)
        
        bottomButtonView.widthAnchor.constraintEqualToAnchor(mainStackView.widthAnchor, multiplier: 0.9).active = true
        bottomButtonView.heightAnchor.constraintEqualToConstant(bottomButtonHeight).active = true

        KyoozUtils.doInMainQueueAsync() {
            self.reloadData(nil)
            self.updateAlphaLevels()
        }
        
        view.addObserver(self, forKeyPath: "center", options: .New, context: &observationContext)
        view.bringSubviewToFront(nowPlayingBarVC.view)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradiantLayer.frame = view.bounds
    }
    
    private func createBottomButtonView() -> UIView {
        let font = ThemeHelper.smallFontForStyle(.Medium)
        func createAndConfigureButton(title:String, selector:Selector) -> UIButton {
            let button = UIButton()
            button.setTitle(title, forState: .Normal)
			button.setTitleColor(ThemeHelper.defaultFontColor, forState: .Normal)
			button.setTitleColor(ThemeHelper.defaultVividColor, forState: .Highlighted)
            button.addTarget(self, action: selector, forControlEvents: .TouchUpInside)
            if let label = button.titleLabel {
                label.alpha = ThemeHelper.defaultButtonTextAlpha
                label.font = font
                label.textAlignment = .Center
				button.heightAnchor.constraintEqualToConstant(bottomButtonHeight).active = true
				button.widthAnchor.constraintEqualToConstant(label.intrinsicContentSize().width + 20).active = true
            }
            return button
		}
		
		func stackViewWrapperForViews(views:[UIView]) -> UIView {
			let stackView = UIStackView(arrangedSubviews: views)
			stackView.axis = .Horizontal
			stackView.distribution = .EqualSpacing
            
            var apply = false
            views.forEach() {
                if apply {
                    $0.layer.borderColor = UIColor.darkGrayColor().CGColor
                    $0.layer.borderWidth = 1
                }
                apply = !apply
            }

			let wrapperView = UIView()
			ConstraintUtils.applyStandardConstraintsToView(subView: stackView, parentView: wrapperView)
			wrapperView.layer.cornerRadius = 5
			wrapperView.layer.borderColor = UIColor.darkGrayColor().CGColor
			wrapperView.layer.borderWidth = 1
			wrapperView.layer.masksToBounds = true
			return wrapperView
		}
		
        let goToAlbumButton = createAndConfigureButton("ALBUM", selector: #selector(self.goToAlbum(_:)))
        let goToArtistButton = createAndConfigureButton("ARTIST", selector: #selector(self.goToArtist(_:)))
        let addToPlaylistButton = createAndConfigureButton("＋  ", selector: #selector(self.addToPlaylist(_:)))
		addToPlaylistButton.titleLabel?.font = UIFont.systemFontOfSize(20)
		let hideButton = createAndConfigureButton("HIDE", selector: #selector(self.collapseViewController(_:)))
		
		let goToStack = stackViewWrapperForViews([goToAlbumButton, goToArtistButton, addToPlaylistButton])
		let otherStack = stackViewWrapperForViews([hideButton])
        
        let stackView = UIStackView(arrangedSubviews: [goToStack, otherStack])
        stackView.axis = .Horizontal
        stackView.distribution = .EqualCentering
        stackView.alignment = .Center
        return stackView
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return expanded
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
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
        let currentY = maxY - frame.origin.y
        
        let expandedFraction = KyoozUtils.cap((currentY/maxY), min: 0, max: 1)
        
        let collapsedFraction = 1 - expandedFraction
        
        collapseButton?.alpha = expandedFraction
        albumArtPageVC.view.alpha = expandedFraction
        
        func updateAlphaForView(view:UIView, fraction:CGFloat) {
            if fraction > 0.75 {
                view.alpha = (fraction - 0.75) * 4
            } else {
                view.alpha = 0
            }
        }
        
        updateAlphaForView(nowPlayingBarVC.view, fraction: collapsedFraction)
        updateAlphaForView(labelWrapperVC.view, fraction: expandedFraction)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradiantLayer.opacity = Float(expandedFraction)
        CATransaction.commit()

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
