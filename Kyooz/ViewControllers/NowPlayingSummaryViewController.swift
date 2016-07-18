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
    
    private lazy var audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    private let albumArtPageVC: NowPlayingPageViewController = ImagePageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
    
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
        gradiant.colors = [
			ThemeHelper.defaultTableCellColor.CGColor,
			UIColor.clearColor().CGColor,
			UIColor.clearColor().CGColor,
			ThemeHelper.defaultTableCellColor.CGColor
		]
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
        Playlists.showAvailablePlaylists(forAddingTracks:[nowPlayingItem])
    }
	
    private func goToVCWithGrouping(libraryGrouping:LibraryGrouping) {
		if let nowPlayingItem = audioQueuePlayer.nowPlayingItem,
			let sourceData = MediaQuerySourceData(filterEntity: nowPlayingItem,
			                                      parentLibraryGroup: libraryGrouping,
			                                      baseQuery: nil) {
			
			ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(sourceData,
			                                                                            parentGroup: libraryGrouping,
			                                                                            entity: nowPlayingItem)
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
		view.add(subView: blurView, with: Anchor.standardAnchors)
        blurView.contentView.layer.addSublayer(gradiantLayer)
		
		func configure(vc vc:UIViewController, withHeight height:CGFloat, widthAnchor:NSLayoutDimension, multiplier:CGFloat) {
			vc.view.heightAnchor.constraintEqualToConstant(height).active = true
			vc.view.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: multiplier).active = true
			addChildViewController(vc)
			vc.didMoveToParentViewController(self)
		}
		
		view.add(subView: nowPlayingBarVC.view, with: [.Top, .CenterX])
		configure(vc: nowPlayingBarVC,
		          withHeight: self.dynamicType.CollapsedHeight,
		          widthAnchor: view.widthAnchor,
		          multiplier: 1)

        let bottomButtonView = createBottomButtonView()

		let mainStackView = UIStackView(arrangedSubviews: [
			labelWrapperVC.view,
			albumArtPageVC.view,
			playbackProgressVC.view,
			playbackControlsVC.view,
			bottomButtonView
		])
		
        mainStackView.axis = .Vertical
        mainStackView.distribution = .EqualSpacing
        mainStackView.alignment = .Center
        
        view.add(subView: mainStackView, with: [.Left, .Right, .CenterY])
        mainStackView.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 0.95).active = true
		
		let anchor_mult:(NSLayoutDimension, CGFloat) = UIScreen.heightClass == .iPhone4 ?
			(view.heightAnchor, 0.55) :
			(albumArtPageVC.view.widthAnchor, 0.9)
		
		albumArtPageVC.view.heightAnchor.constraintEqualToAnchor(anchor_mult.0, multiplier: anchor_mult.1).active = true
		albumArtPageVC.view.widthAnchor.constraintEqualToAnchor(mainStackView.widthAnchor).active = true
        addChildViewController(albumArtPageVC)
        albumArtPageVC.didMoveToParentViewController(self)
		
		configure(vc: labelWrapperVC,
		          withHeight: self.dynamicType.CollapsedHeight,
		          widthAnchor: mainStackView.widthAnchor,
		          multiplier: 0.95)
		
		configure(vc: playbackProgressVC,
		          withHeight: 25,
		          widthAnchor: view.widthAnchor,
		          multiplier: 0.95)

        configure(vc: playbackControlsVC,
                  withHeight: 50,
                  widthAnchor: mainStackView.widthAnchor,
                  multiplier: 0.9)
		
        
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
				label.lineBreakMode = .ByTruncatingTail
				button.heightAnchor.constraintEqualToConstant(bottomButtonHeight).active = true
				button.widthAnchor.constraintEqualToConstant(label.intrinsicContentSize().width + 20).active = true
            }
            return button
		}
		
		func stackViewWrapperForViews(views:[UIView]) -> UIView {
			let stackView = UIStackView(arrangedSubviews: views)
			stackView.axis = .Horizontal
			stackView.distribution = .EqualSpacing
            
            1.stride(to: views.count, by: 2).forEach {
                let view = views[$0]
                view.layer.borderColor = UIColor.darkGrayColor().CGColor
                view.layer.borderWidth = 1
            }

			let wrapperView = UIView()
            wrapperView.add(subView: stackView, with: Anchor.standardAnchors)
			wrapperView.layer.cornerRadius = 5
			wrapperView.layer.borderColor = UIColor.darkGrayColor().CGColor
			wrapperView.layer.borderWidth = 1
			wrapperView.layer.masksToBounds = true
			return wrapperView
		}
		
        let goToAlbumButton = createAndConfigureButton("ALBUM", selector: #selector(self.goToAlbum(_:)))
        let goToArtistButton = createAndConfigureButton("ARTIST", selector: #selector(self.goToArtist(_:)))
        let addToPlaylistButton = createAndConfigureButton(UIScreen.widthClass == .iPhone345 ? "ADD TO.." : "ADD TO PLAYLIST",
                                                           selector: #selector(self.addToPlaylist(_:)))
        
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
		
		let imageWrapper = { return ImageWrapperViewController(track: nowPlayingItem,
		                                                       isPresentedVC: true,
		                                                       representingIndex: index,
		                                                       size: self.albumArtPageVC.view.frame.size) }
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
        
        let expandedFraction = (currentY/maxY).cap(min: 0, max: 1)
        
        let collapsedFraction = 1 - expandedFraction
        
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
        notificationCenter.addObserver(self,
                                       selector: #selector(self.reloadData(_:)),
                                       name: AudioQueuePlayerUpdate.nowPlayingItemChanged.rawValue,
                                       object: audioQueuePlayer)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(self.reloadData(_:)),
                                       name: AudioQueuePlayerUpdate.playbackStateUpdate.rawValue,
                                       object: audioQueuePlayer)
        
		//this is for refreshing the page views
        notificationCenter.addObserver(self,
                                       selector: #selector(self.reloadData(_:)),
                                       name: AudioQueuePlayerUpdate.queueUpdate.rawValue,
                                       object: audioQueuePlayer)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(self.reloadData(_:)),
                                       name: UIApplicationDidBecomeActiveNotification,
                                       object: UIApplication.sharedApplication())
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}
