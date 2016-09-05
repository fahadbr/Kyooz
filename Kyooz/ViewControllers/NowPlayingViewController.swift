//
//  NowPlayingViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 4/11/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

private let bottomButtonHeight:CGFloat = 30

final class NowPlayingViewController: UIViewController {
    //MARK: - PROPERTIES
	
	private typealias This = NowPlayingViewController
	static let miniPlayerHeight:CGFloat = 45
	static let heightScale:CGFloat = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width)/667
    
    private lazy var audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    private let albumArtPageVC: NowPlayingPageViewController = ImagePageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    
    private let playbackProgressVC = PlaybackProgressViewController.instance
	private let nowPlayingBarVC = MiniPlayerViewController()
	private let playbackControlsVC = PlaybackControlsViewController()
    private lazy var labelWrapperVC:LabelStackWrapperViewController = {
        let track = self.audioQueuePlayer.nowPlayingItem
        let index = self.audioQueuePlayer.indexOfNowPlayingItem
        let vc = LabelStackWrapperViewController(track: track,
                                                 isPresentedVC: true,
                                                 representingIndex: index,
                                                 useSmallFont: This.heightScale < 0.8)
        return vc
    }()
    
    
    private let gradiantLayer:CAGradientLayer = {
        let gradiant = CAGradientLayer()
        gradiant.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradiant.endPoint = CGPoint(x: 0.5, y: 0)
        gradiant.colors = [
			ThemeHelper.defaultTableCellColor.cgColor,
			UIColor.clear.cgColor,
			UIColor.clear.cgColor,
			ThemeHelper.defaultTableCellColor.cgColor
		]
        gradiant.locations = [0.0,0.25,0.75,1.0]
        return gradiant
    }()
    
    private var observationContext:UInt8 = 123
    
    var expanded:Bool = false {
        didSet{
            UIView.animate(withDuration: 0.5) { 
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
	
    //MARK: - FUNCTIONS
    deinit {
        Logger.debug("deinitializing NowPlayingSummaryViewController")
        self.unregisterForNotifications()
    }

    
    func goToArtist(_ sender: AnyObject) {
        goToVCWithGrouping(LibraryGrouping.Artists)
    }
    
    func goToAlbum(_ sender: AnyObject) {
        goToVCWithGrouping(LibraryGrouping.Albums)
    }
    
    func addToPlaylist(_ sender: AnyObject) {
        guard let nowPlayingItem = audioQueuePlayer.nowPlayingItem else { return }
        Playlists.showAvailablePlaylists(forAddingTracks:[nowPlayingItem])
    }
	
    private func goToVCWithGrouping(_ libraryGrouping:LibraryGrouping) {
		if let nowPlayingItem = audioQueuePlayer.nowPlayingItem,
			let sourceData = MediaQuerySourceData(filterEntity: nowPlayingItem,
			                                      parentLibraryGroup: libraryGrouping,
			                                      baseQuery: nil) {
			
			ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(sourceData,
			                                                                            parentGroup: libraryGrouping,
			                                                                            entity: nowPlayingItem)
		}
    }
	
    func collapseViewController(_ sender: AnyObject) {
        RootViewController.instance.animatePullablePanel(shouldExpand: false)
    }
	
    //MARK: - FUNCTIONS: - Overridden functions
    override func viewDidLoad() {
        super.viewDidLoad()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        registerForNotifications()
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
		view.add(subView: blurView, with: Anchor.standardAnchors)
        blurView.contentView.layer.addSublayer(gradiantLayer)
		
		func configure(vc:UIViewController, withHeight height:CGFloat, widthAnchor:NSLayoutDimension, multiplier:CGFloat) {
			vc.view.heightAnchor.constraint(equalToConstant: height).isActive = true
			vc.view.widthAnchor.constraint(equalTo: widthAnchor, multiplier: multiplier).isActive = true
			addChildViewController(vc)
			vc.didMove(toParentViewController: self)
		}
		
		view.add(subView: nowPlayingBarVC.view, with: [.top, .centerX])
		configure(vc: nowPlayingBarVC,
		          withHeight: This.miniPlayerHeight,
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
		
        mainStackView.axis = .vertical
        mainStackView.distribution = .equalSpacing
        mainStackView.alignment = .center
        
        view.add(subView: mainStackView, with: [.left, .right, .centerY])
        mainStackView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.95).isActive = true
		
		let anchor_mult:(NSLayoutDimension, CGFloat) = UIScreen.heightClass == .iPhone4 ?
			(view.heightAnchor, 0.55) :
			(albumArtPageVC.view.widthAnchor, 0.9)
		
		albumArtPageVC.view.heightAnchor.constraint(equalTo: anchor_mult.0, multiplier: anchor_mult.1).isActive = true
		albumArtPageVC.view.widthAnchor.constraint(equalTo: mainStackView.widthAnchor).isActive = true
        addChildViewController(albumArtPageVC)
        albumArtPageVC.didMove(toParentViewController: self)
		
		configure(vc: labelWrapperVC,
		          withHeight: This.miniPlayerHeight,
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
		
        
        bottomButtonView.widthAnchor.constraint(equalTo: mainStackView.widthAnchor, multiplier: 0.9).isActive = true
        bottomButtonView.heightAnchor.constraint(equalToConstant: bottomButtonHeight).isActive = true

        KyoozUtils.doInMainQueueAsync() {
            self.reloadData(nil)
            self.updateAlphaLevels()
        }
        
        view.addObserver(self, forKeyPath: "center", options: .new, context: &observationContext)
        view.bringSubview(toFront: nowPlayingBarVC.view)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradiantLayer.frame = view.bounds
    }
    
    private func createBottomButtonView() -> UIView {
        let font = ThemeHelper.smallFontForStyle(.medium)
		
        func createAndConfigureButton(_ title:String, selector:Selector) -> UIButton {
            let button = UIButton()
            button.setTitle(title, for: UIControlState())
			button.setTitleColor(ThemeHelper.defaultFontColor, for: UIControlState())
			button.setTitleColor(ThemeHelper.defaultVividColor, for: .highlighted)
            button.addTarget(self, action: selector, for: .touchUpInside)
            if let label = button.titleLabel {
                label.alpha = ThemeHelper.defaultButtonTextAlpha
                label.font = font
                label.textAlignment = .center
				label.lineBreakMode = .byTruncatingTail
				button.heightAnchor.constraint(equalToConstant: bottomButtonHeight).isActive = true
				button.widthAnchor.constraint(equalToConstant: label.intrinsicContentSize.width + 20).isActive = true
            }
            return button
		}
		
		func stackViewWrapperForViews(_ views:[UIView]) -> UIView {
			let stackView = UIStackView(arrangedSubviews: views)
			stackView.axis = .horizontal
			stackView.distribution = .equalSpacing
            
            stride(from: 1, to: views.count, by: 2).forEach {
                let view = views[$0]
                view.layer.borderColor = UIColor.darkGray.cgColor
                view.layer.borderWidth = 1
            }

			let wrapperView = UIView()
            wrapperView.add(subView: stackView, with: Anchor.standardAnchors)
			wrapperView.layer.cornerRadius = 5
			wrapperView.layer.borderColor = UIColor.darkGray.cgColor
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
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        return stackView
    }
    
    override var prefersStatusBarHidden: Bool {
        return expanded
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
	

    func reloadData(_ notification:Notification?) {
        guard UIApplication.shared.applicationState == UIApplicationState.active else { return }
        
        func transitionPageVC(_ pageVC:NowPlayingPageViewController, withVC vc:()->WrapperViewController){
			if !((pageVC.viewControllers?.first as? WrapperViewController)?.isPresentedVC ?? false)
				 || pageVC.refreshNeeded {
				pageVC.refreshNeeded = false
				pageVC.setViewControllers([vc()], direction: .forward, animated: false, completion: nil)
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
            if let image = (self.albumArtPageVC.viewControllers?.first as? ImageWrapperViewController)?.imageView.image?.cgImage {
                self.view.layer.contents = image
            }
        }
    }
    


    
    //MARK: - FUNCTIONS: - KVOFunction
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
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
        let maxY = frame.height - This.miniPlayerHeight
        let currentY = maxY - frame.origin.y
        
        let expandedFraction = (currentY/maxY).cap(min: 0, max: 1)
        
        let collapsedFraction = 1 - expandedFraction
        
        albumArtPageVC.view.alpha = expandedFraction
        
        func updateAlphaForView(_ view:UIView, fraction:CGFloat) {
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
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(self.reloadData(_:)),
                                       name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.nowPlayingItemChanged.rawValue),
                                       object: audioQueuePlayer)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(self.reloadData(_:)),
                                       name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.playbackStateUpdate.rawValue),
                                       object: audioQueuePlayer)
        
		//this is for refreshing the page views
        notificationCenter.addObserver(self,
                                       selector: #selector(self.reloadData(_:)),
                                       name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.queueUpdate.rawValue),
                                       object: audioQueuePlayer)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(self.reloadData(_:)),
                                       name: NSNotification.Name.UIApplicationDidBecomeActive,
                                       object: UIApplication.shared)
    }
    
    private func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

}
