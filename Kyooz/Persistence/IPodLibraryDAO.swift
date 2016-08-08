//
//  IPodLibraryDAO.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/3/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer
import StoreKit

class IPodLibraryDAO {
    
    static func queryMediaItemsFromIds(_ persistentIds:[AnyObject]) -> [AudioTrack]? {
        var queriedMediaItems = [AnyObject]()
        KyoozUtils.performWithMetrics(blockDescription: "Query of List of IDs from iPod Library") {
            for mediaId in persistentIds {
                let mediaItem = queryMediaItemFromId(mediaId)
                if(mediaItem == nil) {
                    Logger.debug("query for mediaItem with persistentID:\(mediaId) did not return anything")
                    continue
                }
                queriedMediaItems.append(mediaItem!)
            }
        }
        return queriedMediaItems as? [AudioTrack]
    }
    
    static func queryMediaItemFromId(_ persistentId:AnyObject) -> AudioTrack? {
        let query = MPMediaQuery()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: persistentId, forProperty: MPMediaItemPropertyPersistentID))
        return query.items?.first
    }
    
    
    @available(iOS 9.3, *)
    static func addTracksToPlaylist(_ playlist:MPMediaPlaylist, tracks:[MPMediaItem]) {
        validateAndExecute() {
            let message = playlist.items.count != 0 ? "Saved changes to playlist \(playlist.name ?? "")" : "Created playlist \(playlist.name ?? "")"
            playlist.add(tracks, completionHandler: { (error) in
                if let e = error {
                    KyoozUtils.showPopupError(withTitle: "Error saving tracks to playlist \(playlist.name)",
						withThrownError: e,
						presentationVC: nil)
					
                } else {
                    KyoozUtils.doInMainQueueAfterDelay(0.5) {
						Playlists.setMostRecentlyModified(playlist: playlist)
                        ShortNotificationManager.instance.presentShortNotification(withMessage:message)
                    }
                }
            })
        }
    }
    
    @available(iOS 9.3, *)
    static func createPlaylist(named name:String, withTracks tracks:[MPMediaItem]) {
        validateAndExecute() {
            let metaData = MPMediaPlaylistCreationMetadata(name: name)
            MPMediaLibrary.default().getPlaylist(with: UUID(), creationMetadata: metaData, completionHandler: { (createdPlaylist, error) in
                guard error == nil else {
                    KyoozUtils.showPopupError(withTitle: "Could not create playlist with name \(name)",
						withThrownError: error!,
						presentationVC: nil)
					
                    return
                }
                guard let playlist = createdPlaylist else {
                    KyoozUtils.showPopupError(withTitle: "Could not create playlist with name \(name)",
						withMessage: "iTunes Media Library did not create the playlist",
						presentationVC: nil)
					
                    return
                }
                addTracksToPlaylist(playlist, tracks: tracks)
                
            })
        }
    }
    
    @available(iOS 9.3, *)
    private static func validateAndExecute(_ block:()->()) {
        switch SKCloudServiceController.authorizationStatus() {
        case .notDetermined :
            SKCloudServiceController.requestAuthorization({ (status) in
                if status == .authorized {
                    block()
                }
            })
        case .authorized:
            block()
        default:
			let b = MenuBuilder()
                .with(title: "Access to modify the iTunes Library is not available.  Please grant access to the media library in the system settings")
            
            let goToSettingsAction = KyoozMenuAction(title: "Jump To Settings") {
                if let url = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.openURL(url)
                } else {
                    KyoozUtils.showPopupError(withTitle: "Error with opening URL to settings", withMessage: nil, presentationVC: nil)
                }
            }
            b.with(options: goToSettingsAction)
            KyoozUtils.showMenuViewController(b.viewController)
            break
        }
    }
    
}
