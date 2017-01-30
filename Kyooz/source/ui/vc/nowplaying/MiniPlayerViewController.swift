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
    private let labelPageVC = LabelPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
	
	override func viewDidLoad() {
		super.viewDidLoad()
		//accessability configuration
		
        playPauseButton.isAccessibilityElement = true
		playPauseButton.accessibilityLabel = "miniPlayerPlayButton"
		playPauseButton.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitAllowsDirectInteraction
		
		//progressBarConfig
		ConstraintUtils.applyConstraintsToView(withAnchors: [.left, .right, .top], subView: progressView, parentView: view)
		progressView.progressTintColor = ThemeHelper.defaultVividColor
		progressView.trackTintColor = UIColor.darkGray
		
		
		//playPauseButton config
		ConstraintUtils.applyConstraintsToView(withAnchors: [.left, .top, .bottom], subView: playPauseButton, parentView: view)
		playPauseButton.widthAnchor.constraint(equalTo: playPauseButton.heightAnchor).isActive = true
		playPauseButton.scale = 0.7
		playPauseButton.hasOuterFrame = false
		
		//menuButton config
		ConstraintUtils.applyConstraintsToView(withAnchors: [.right, .top, .bottom], subView: menuButton, parentView: view)
		menuButton.widthAnchor.constraint(equalTo: menuButton.heightAnchor).isActive = true
		menuButton.position = 0.6
		menuButton.color = UIColor.white
		menuButton.addTarget(self, action: #selector(self.menuButtonPressed(_:)), for: .touchUpInside)
        
        ConstraintUtils.applyConstraintsToView(withAnchors: [.top, .bottom], subView: labelPageVC.view, parentView: view)
        labelPageVC.view.leftAnchor.constraint(equalTo: playPauseButton.rightAnchor).isActive = true
        labelPageVC.view.rightAnchor.constraint(equalTo: menuButton.leftAnchor).isActive = true
        labelPageVC.view.isAccessibilityElement = true
		labelPageVC.view.accessibilityLabel = "miniPlayerTrackDetails"
		labelPageVC.view.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitAllowsDirectInteraction
		
        KyoozUtils.doInMainQueueAsync() {
            self.updateButtonStates()
        }
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		PlaybackProgressViewController.instance.addProgressObserver(self)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		PlaybackProgressViewController.instance.removeProgressObserver(self)
	}
	
	func updateProgress(_ percentComplete: Float) {
		progressView.setProgress(percentComplete, animated: true)
	}
    
    override func updateButtonStates() {
        super.updateButtonStates()
        if !((labelPageVC.viewControllers?.first as? WrapperViewController)?.isPresentedVC ?? false) || labelPageVC.refreshNeeded {
            let nowPlayingItem = audioQueuePlayer.nowPlayingItem
            let index = audioQueuePlayer.indexOfNowPlayingItem
            let labelWrapper = LabelStackWrapperViewController(track: nowPlayingItem, isPresentedVC: true, representingIndex: index)
            labelPageVC.refreshNeeded = false
            labelPageVC.setViewControllers([labelWrapper], direction: .forward, animated: false, completion: nil)
        }
    }
	
	func menuButtonPressed(_ sender: AnyObject) {
		guard let nowPlayingItem = audioQueuePlayer.nowPlayingItem else {
			return
		}
		
		let b = MenuBuilder()
            .with(title: nowPlayingItem.trackTitle)
            .with(details: "\(nowPlayingItem.albumArtist ?? "")  —  \(nowPlayingItem.albumTitle ?? "")")
            .with(originatingCenter: menuButton.superview?.convert(menuButton.center, to: UIScreen.main.coordinateSpace))
		
        .with(options:
            KyoozMenuAction(title: KyoozConstants.JUMP_TO_ALBUM) {
                self.goToVCWithGrouping(LibraryGrouping.Albums, nowPlayingItem: nowPlayingItem)
            },
               KyoozMenuAction(title: KyoozConstants.JUMP_TO_ARTIST) {
                self.goToVCWithGrouping(LibraryGrouping.Artists, nowPlayingItem: nowPlayingItem)
            }
        )
        
        .with(options: KyoozMenuAction(title: KyoozConstants.ADD_TO_PLAYLIST) {
            Playlists.showAvailablePlaylists(forAddingTracks:[nowPlayingItem])
            })

		KyoozUtils.showMenuViewController(b.viewController)
	}
	
	private func goToVCWithGrouping(_ libraryGrouping:LibraryGrouping, nowPlayingItem:AudioTrack) {
		if let sourceData = MediaQuerySourceData(filterEntity: nowPlayingItem, parentLibraryGroup: libraryGrouping, baseQuery: nil) {
			ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(sourceData, parentGroup: libraryGrouping, entity: nowPlayingItem)
		}
	}
    
    override func registerForNotifications() {
        super.registerForNotifications()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(self.updateButtonStates),
                                       name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.nowPlayingItemChanged.rawValue), object: audioQueuePlayer)
        //this is for refreshing the page views
        notificationCenter.addObserver(self, selector: #selector(self.updateButtonStates),
                                       name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.queueUpdate.rawValue), object: audioQueuePlayer)
        
    }
}
