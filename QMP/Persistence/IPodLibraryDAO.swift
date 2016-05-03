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
    
    static func queryMediaItemsFromIds(persistentIds:[AnyObject]) -> [AudioTrack]? {
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
    
    static func queryMediaItemFromId(persistentId:AnyObject) -> AudioTrack? {
        let query = MPMediaQuery()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: persistentId, forProperty: MPMediaItemPropertyPersistentID))
        return query.items?.first
    }
    
    
    @available(iOS 9.3, *)
    static func addTracksToPlaylist(playlist:MPMediaPlaylist, tracks:[MPMediaItem]) {
        validateAndExecute() {
            let message = playlist.items.count != 0 ? "Saved changes to playlist \(playlist.name ?? "")" : "Created playlist \(playlist.name ?? "")"
            playlist.addMediaItems(tracks, completionHandler: { (error) in
                if let e = error {
                    KyoozUtils.showPopupError(withTitle: "Error saving tracks to playlist \(playlist.name)", withThrownError: e, presentationVC: nil)
                } else {
                    KyoozUtils.doInMainQueueAfterDelay(1) {
                        ShortNotificationManager.instance.presentShortNotificationWithMessage(message, withSize: .Small)
                    }
                }
            })
        }
    }
    
    @available(iOS 9.3, *)
    static func createPlaylistWithName(name:String, tracks:[MPMediaItem]) {
        validateAndExecute() {
            let metaData = MPMediaPlaylistCreationMetadata(name: name)
            MPMediaLibrary.defaultMediaLibrary().getPlaylistWithUUID(NSUUID(), creationMetadata: metaData, completionHandler: { (createdPlaylist, error) in
                guard error == nil else {
                    KyoozUtils.showPopupError(withTitle: "Could not create playlist with name \(name)", withThrownError: error!, presentationVC: nil)
                    return
                }
                guard let playlist = createdPlaylist else {
                    KyoozUtils.showPopupError(withTitle: "Could not create playlist with name \(name)", withMessage: "iTunes Media Library did not create the playlist", presentationVC: nil)
                    return
                }
                addTracksToPlaylist(playlist, tracks: tracks)
                
            })
        }
    }
    
    @available(iOS 9.3, *)
    private static func validateAndExecute(block:()->()) {
        switch SKCloudServiceController.authorizationStatus() {
        case .NotDetermined, .Denied:
            SKCloudServiceController.requestAuthorization({ (status) in
                if status == .Authorized {
                    block()
                }
            })
        case .Authorized:
            block()
        default:
			KyoozUtils.showPopupError(withTitle: "Access to modify the iTunes Library is not available.  Please change in settings", withMessage: nil, presentationVC: nil)
            break
        }
    }
    
}