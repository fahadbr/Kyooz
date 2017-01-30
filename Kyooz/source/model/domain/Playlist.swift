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
	
	static func setMostRecentlyModified(playlist:AudioTrackCollection!) {
        guard playlist != nil else {
            mostRecentlyModifiedPlaylist = nil
            return
        }
        
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
		addToPlaylistVC.modalTransitionStyle = .crossDissolve
		
		presentingVC.present(addToPlaylistVC, animated: true, completion: nil)
		
	}
	
	
    private static func createNewKyoozPlaylist(named name:String, with tracks:[AudioTrack], completionAction:(()->Void)? = nil) {
        do {
            try KyoozPlaylistManager.instance.create(playlist:KyoozPlaylist(name: name), withTracks: tracks)
            completionAction?()
        } catch let error {
            KyoozUtils.showPopupError(withTitle: "Failed to save playlist with name \(name)", withThrownError: error, presentationVC: nil)
        }
    }
    
    
    @available(iOS 9.3, *)
    private static func createNewItunesPlaylist(named name:String, with tracks:[AudioTrack], completionAction:(()->Void)? = nil) {
        guard let mediaItems = tracks as? [MPMediaItem] else {
            KyoozUtils.showPopupError(withTitle: "Couldn't save playlist with name \(name)",
                                      withMessage: "Some or all of the tracks are not part of the iTunes Library",
                                      presentationVC: nil)
            return
        }
        IPodLibraryDAO.createPlaylist(named: name, withTracks: mediaItems)
        completionAction?()
    }
    
    @available(iOS 9.3, *)
    static func showPlaylistTypeInfoView(_ presentationController:UIViewController = ContainerViewController.instance,
                                         completionAction:(()->Void)? = nil) {
        do {
            let textVC = try TextViewController(fileName: "PlaylistTypeDescriptions",
                                                documentType: .html,
                                                showDismissButton: true,
                                                completionAction: completionAction)
            
            presentationController.present(UINavigationController(rootViewController:textVC),
                                                         animated: true,
                                                         completion: nil)
        } catch let error {
            Logger.error("Error with loading playlist type description file: \(error.description)")
        }
    }
	
	
	
    static func showPlaylistCreationController(for tracks:[AudioTrack],
                                                   presentationController:UIViewController = ContainerViewController.instance,
                                                   completionAction:(()->Void)? = nil) {
		let ac = UIAlertController(title: "Save as playlist as..",
		                           message: "Enter the name you would like to save the playlist as",
		                           preferredStyle: .alert)
        
		ac.view.tintColor = ThemeHelper.defaultVividColor
		ac.addTextField(configurationHandler: nil)

        
        let kyoozOption = UIAlertAction(title: "Kyooz Playlist", style: .default, handler: { (action) -> Void in
            guard let text = ac.textFields?.first?.text, !text.isEmpty else {
                Logger.error("No name found")
                return
            }
            createNewKyoozPlaylist(named: text, with: tracks, completionAction: completionAction)
        })
        ac.addAction(kyoozOption)
        
        if #available(iOS 9.3, *) {
            let itunesOption = UIAlertAction(title: "iTunes Playlist", style: .default, handler: { (action) -> Void in
                guard let text = ac.textFields?.first?.text, !text.isEmpty else {
                    Logger.error("No name found")
                    return
                }
                createNewItunesPlaylist(named: text, with: tracks, completionAction: completionAction)
            })
            ac.addAction(itunesOption)
            
            let infoOption = UIAlertAction(title: "What's the difference?", style: .default) { _ in
                showPlaylistTypeInfoView(presentationController) {
                    showPlaylistCreationController(for: tracks,
                                                   presentationController: presentationController,
                                                   completionAction: completionAction)
                }
            }
            ac.addAction(infoOption)
        }
		
		ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		presentationController.present(ac, animated: true, completion: {
			ac.view.tintColor = ThemeHelper.defaultVividColor
		})
		
	}
	
}




