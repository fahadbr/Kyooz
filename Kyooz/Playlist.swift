//
//  Playlist.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/23/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

enum PlaylistType : EnumNameDescriptable, CustomStringConvertible {
	
	case kyooz
	
	@available(iOS 9.3, *)
	case iTunes
	
	var description: String {
		switch self {
		case .kyooz:
			return "KYOOZ PLAYLIST"
		case .iTunes:
			return "ITUNES PLAYLIST"
			
		}
	}
	
}

struct Playlists {

	typealias PlaylistReference = (playlist:AudioTrackCollection, type:PlaylistType)

	private (set) static var mostRecentlyModifiedPlaylist:PlaylistReference?
	
	static func setMostRecentlyModified(playlist playlist:AudioTrackCollection) {
		let type:PlaylistType
		switch playlist {
		case is MPMediaPlaylist:
			if #available(iOS 9.3, *) {
				type = .iTunes
			} else {
				fatalError("itunes playlist modification is not supported prior to iOS 9.3")
			}
		case is KyoozPlaylist:
			type = .kyooz
		default:
			fatalError("unknown audio track collection type is being set as playlist")
		}
		
		mostRecentlyModifiedPlaylist = (playlist, type)
	}
	
	static func showAvailablePlaylists(forAddingTracks tracks:[AudioTrack],
	                                                   usingTitle title:String? = nil,
	                                                              completionAction:(()->Void)? = nil) {
		let presentingVC = ContainerViewController.instance
		let addToPlaylistVC = AddToPlaylistViewController(tracksToAdd: tracks, title: title, completionAction: completionAction)
		addToPlaylistVC.modalTransitionStyle = .CrossDissolve
		
		presentingVC.presentViewController(addToPlaylistVC, animated: true, completion: nil)
		
	}
	
	static func showPlaylistCreationControllerForTracks(tracks:[AudioTrack], completionAction:(()->Void)? = nil) {
		if #available(iOS 9.3, *) {
			let menuBuilder = MenuBuilder()
                .with(title: "Select which type of playlist to create")
			let createKyoozPlaylistAction = KyoozMenuAction(title: "KYOOZ PLAYLIST") {
				showKyoozPlaylistCreationControllerForTracks(tracks, completionAction: completionAction)
			}
			let createItunesPlaylistAction = KyoozMenuAction(title: "ITUNES PLAYLIST") {
				showITunesPlaylistCreationControllerForTracks(tracks, completionAction: completionAction)
			}
			menuBuilder.with(options: createKyoozPlaylistAction, createItunesPlaylistAction)
			
            menuBuilder.with(options: KyoozMenuAction(title: "What's the difference?") {
                showPlaylistTypeInfoView()
            })
			KyoozUtils.showMenuViewController(menuBuilder.viewController)
		} else {
			showKyoozPlaylistCreationControllerForTracks(tracks, completionAction: completionAction)
		}
	}
	
	static func showKyoozPlaylistCreationControllerForTracks(tracks:[AudioTrack], completionAction:(()->Void)? = nil) {
		let saveAction = { (text:String) in
			
			do {
				try KyoozPlaylistManager.instance.create(playlist:KyoozPlaylist(name: text), withTracks: tracks)
				completionAction?()
			} catch let error {
				KyoozUtils.showPopupError(withTitle: "Failed to save playlist with name \(text)", withThrownError: error, presentationVC: nil)
			}
		}
		showPlaylistCreationControllerForTracks(tracks, playlistTypeName: "Kyooz", saveAction: saveAction, completionAction: completionAction)
		
	}
	
	
	@available(iOS 9.3, *)
	static func showITunesPlaylistCreationControllerForTracks(tracks:[AudioTrack], completionAction:(()->Void)? = nil) {
		let saveAction = { (text:String) in
			guard let mediaItems = tracks as? [MPMediaItem] else {
				KyoozUtils.showPopupError(withTitle: "Couldn't save playlist with name \(text)", withMessage: "In compatible tracks in current queue", presentationVC: nil)
				return
			}
			IPodLibraryDAO.createPlaylistWithName(text, tracks: mediaItems)
		}
		showPlaylistCreationControllerForTracks(tracks, playlistTypeName: "iTunes", saveAction: saveAction, completionAction: completionAction)
		
	}
	
	@available(iOS 9.3, *)
	static func showPlaylistTypeInfoView(presentationController:UIViewController = ContainerViewController.instance) {
		do {
			let textVC = try TextViewController(fileName: "PlaylistTypeDescriptions",
			                                    documentType: .html,
			                                    showDismissButton: true)
			
			presentationController.presentViewController(UINavigationController(rootViewController:textVC),
			                                             animated: true,
			                                             completion: nil)
		} catch let error {
			Logger.error("Error with loading playlist type description file: \(error.description)")
		}
	}
	
	
	private static func showPlaylistCreationControllerForTracks(tracks:[AudioTrack], playlistTypeName:String, saveAction:(nameToSaveAs:String)->(), completionAction:(()->Void)? = nil) {
		let ac = UIAlertController(title: "Save as \(playlistTypeName) Playlist", message: "Enter the name you would like to save the playlist as", preferredStyle: .Alert)
		ac.view.tintColor = ThemeHelper.defaultVividColor
		ac.addTextFieldWithConfigurationHandler(nil)
		let saveAction = UIAlertAction(title: "Save", style: .Default, handler: { (action) -> Void in
			guard let text = ac.textFields?.first?.text else {
				Logger.error("No name found")
				return
			}
			saveAction(nameToSaveAs: text)
		})
		ac.addAction(saveAction)
		ac.preferredAction = saveAction
		ac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
		ContainerViewController.instance.presentViewController(ac, animated: true, completion: {
			ac.view.tintColor = ThemeHelper.defaultVividColor
		})
		
	}
	
}




