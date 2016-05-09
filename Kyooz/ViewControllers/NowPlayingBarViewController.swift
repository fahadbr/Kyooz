//
//  NowPlayingBarViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/8/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class NowPlayingBarViewController: AbstractPlaybackViewController, PlaybackProgressObserver {
	
	private let menuButton = MenuDotsView()
	private let progressView = UIProgressView()
	
	override func viewDidLoad() {
		super.viewDidLoad()
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
	
	func menuButtonPressed(sender: AnyObject) {
		guard let nowPlayingItem = audioQueuePlayer.nowPlayingItem else {
			return
		}
		
		let kmvc = KyoozMenuViewController()
		kmvc.menuTitle = nowPlayingItem.trackTitle
		kmvc.menuDetails = "\(nowPlayingItem.albumArtist ?? "")  —  \(nowPlayingItem.albumTitle ?? "")"
		let center = menuButton.superview?.convertPoint(menuButton.center, toCoordinateSpace: UIScreen.mainScreen().coordinateSpace)
		kmvc.originatingCenter = center
		var jumpToActions = [KyoozMenuActionProtocol]()
		jumpToActions.append(KyoozMenuAction(title: KyoozConstants.JUMP_TO_ALBUM, image: nil) {
			self.goToVCWithGrouping(LibraryGrouping.Albums, nowPlayingItem: nowPlayingItem)
			})
		jumpToActions.append(KyoozMenuAction(title: KyoozConstants.JUMP_TO_ARTIST, image: nil) {
			self.goToVCWithGrouping(LibraryGrouping.Artists, nowPlayingItem: nowPlayingItem)
			})
        kmvc.addActions(jumpToActions)
        kmvc.addActions([KyoozMenuAction(title: KyoozConstants.ADD_TO_PLAYLIST, image: nil) {
            KyoozUtils.showAvailablePlaylistsForAddingTracks([nowPlayingItem])
        }])

		KyoozUtils.showMenuViewController(kmvc)
	}
	
	private func goToVCWithGrouping(libraryGrouping:LibraryGrouping, nowPlayingItem:AudioTrack) {
		if let sourceData = MediaQuerySourceData(filterEntity: nowPlayingItem, parentLibraryGroup: libraryGrouping, baseQuery: nil) {
			ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(sourceData, parentGroup: libraryGrouping, entity: nowPlayingItem)
		}
	}
}