//
//  MiniPlayerViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/8/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class MiniPlayerViewController: AbstractPlaybackViewController, PlaybackProgressObserver {
	
	private let menuButton = MenuDotsView()
	private let progressView = UIProgressView()
    private let labelPageVC = LabelPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
	
	override func viewDidLoad() {
		super.viewDidLoad()
		//accessability configuration
		view.isAccessibilityElement = true
		view.accessibilityIdentifier = "kyoozMiniPlayer"
		view.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitAllowsDirectInteraction
		
		//progressBarConfig
		ConstraintUtils.applyConstraintsToView(withAnchors: [.Left, .Right, .Top], subView: progressView, parentView: view)
		progressView.progressTintColor = ThemeHelper.defaultVividColor
		progressView.trackTintColor = UIColor.darkGrayColor()
		
		
		//playPauseButton config
		ConstraintUtils.applyConstraintsToView(withAnchors: [.Left, .Top, .Bottom], subView: playPauseButton, parentView: view)
		playPauseButton.widthAnchor.constraintEqualToAnchor(playPauseButton.heightAnchor).active = true
		playPauseButton.scale = 0.7
		playPauseButton.hasOuterFrame = false
		
		//menuButton config
		ConstraintUtils.applyConstraintsToView(withAnchors: [.Right, .Top, .Bottom], subView: menuButton, parentView: view)
		menuButton.widthAnchor.constraintEqualToAnchor(menuButton.heightAnchor).active = true
		menuButton.position = 0.6
		menuButton.color = UIColor.whiteColor()
		menuButton.addTarget(self, action: #selector(self.menuButtonPressed(_:)), forControlEvents: .TouchUpInside)
        
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Top, .Bottom], subView: labelPageVC.view, parentView: view)
        labelPageVC.view.leftAnchor.constraintEqualToAnchor(playPauseButton.rightAnchor).active = true
        labelPageVC.view.rightAnchor.constraintEqualToAnchor(menuButton.leftAnchor).active = true
        
        KyoozUtils.doInMainQueueAsync() {
            self.updateButtonStates()
        }
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		PlaybackProgressViewController.instance.addProgressObserver(self)
	}
	
	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		PlaybackProgressViewController.instance.removeProgressObserver(self)
	}
	
	func updateProgress(percentComplete: Float) {
		progressView.setProgress(percentComplete, animated: true)
	}
    
    override func updateButtonStates() {
        super.updateButtonStates()
        if !((labelPageVC.viewControllers?.first as? WrapperViewController)?.isPresentedVC ?? false) || labelPageVC.refreshNeeded {
            let nowPlayingItem = audioQueuePlayer.nowPlayingItem
            let index = audioQueuePlayer.indexOfNowPlayingItem
            let labelWrapper = LabelStackWrapperViewController(track: nowPlayingItem, isPresentedVC: true, representingIndex: index)
            labelPageVC.refreshNeeded = false
            labelPageVC.setViewControllers([labelWrapper], direction: .Forward, animated: false, completion: nil)
        }
    }
	
	func menuButtonPressed(sender: AnyObject) {
		guard let nowPlayingItem = audioQueuePlayer.nowPlayingItem else {
			return
		}
		
		let b = MenuBuilder()
            .with(title: nowPlayingItem.trackTitle)
            .with(details: "\(nowPlayingItem.albumArtist ?? "")  —  \(nowPlayingItem.albumTitle ?? "")")
            .with(originatingCenter: menuButton.superview?.convertPoint(menuButton.center, toCoordinateSpace: UIScreen.mainScreen().coordinateSpace))
		
        b.with(options:
            KyoozMenuAction(title: KyoozConstants.JUMP_TO_ALBUM) {
                self.goToVCWithGrouping(LibraryGrouping.Albums, nowPlayingItem: nowPlayingItem)
            },
               KyoozMenuAction(title: KyoozConstants.JUMP_TO_ARTIST) {
                self.goToVCWithGrouping(LibraryGrouping.Artists, nowPlayingItem: nowPlayingItem)
            }
        )
        
        b.with(options: KyoozMenuAction(title: KyoozConstants.ADD_TO_PLAYLIST) {
            Playlists.showAvailablePlaylists(forAddingTracks:[nowPlayingItem])
            })

		KyoozUtils.showMenuViewController(b.viewController)
	}
	
	private func goToVCWithGrouping(libraryGrouping:LibraryGrouping, nowPlayingItem:AudioTrack) {
		if let sourceData = MediaQuerySourceData(filterEntity: nowPlayingItem, parentLibraryGroup: libraryGrouping, baseQuery: nil) {
			ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(sourceData, parentGroup: libraryGrouping, entity: nowPlayingItem)
		}
	}
    
    override func registerForNotifications() {
        super.registerForNotifications()
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(self.updateButtonStates),
                                       name: AudioQueuePlayerUpdate.nowPlayingItemChanged.rawValue, object: audioQueuePlayer)
        //this is for refreshing the page views
        notificationCenter.addObserver(self, selector: #selector(self.updateButtonStates),
                                       name: AudioQueuePlayerUpdate.queueUpdate.rawValue, object: audioQueuePlayer)
        
    }
}