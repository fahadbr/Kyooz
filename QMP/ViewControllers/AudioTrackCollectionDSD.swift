//
//  AudioEntityTVDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/31/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer
import StoreKit

class AudioTrackCollectionDSD : AudioEntityDSD {
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard !tableView.editing else { return }
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		let entity = sourceData[indexPath]
		
		guard let nextSourceData = sourceData.sourceDataForIndex(indexPath) else {
			Logger.debug("no source data found for indexPath \(indexPath.description)")
			return
		}
		
		//go to specific album track view controller if we are selecting an album collection
        ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(nextSourceData, parentGroup: sourceData.libraryGrouping, entity: entity)
	}
	
}

final class KyoozPlaylistManagerDSD : AudioTrackCollectionDSD {
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
    
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            guard let mutableSourceData = sourceData as? MutableAudioEntitySourceData else {
                return
            }
            do {
                let indexPaths = [indexPath]
                try mutableSourceData.deleteEntitiesAtIndexPaths(indexPaths)
                tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
            } catch let error {
                KyoozUtils.showPopupError(withTitle: "Could not delete playlist: \((sourceData[indexPath] as? KyoozPlaylist)?.name ?? "Unknown Playlist")", withThrownError: error, presentationVC: nil)
                tableView.editing = false
            }

        }
    }
}

/**
This is an abstract class and will crash the system if used
*/
class AddToPlaylistDSD : AudioTrackCollectionDSD {
	
	private let tracksToAdd:[AudioTrack]
	
	init(sourceData:AudioEntitySourceData, reuseIdentifier:String, tracksToAdd:[AudioTrack]) {
		self.tracksToAdd = tracksToAdd
		super.init(sourceData: sourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: nil)
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		fatalError("this is a parent class, must use a subclass")
	}
	
	final func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		if let audioLibraryCell = cell as? MediaLibraryTableViewCell {
			audioLibraryCell.accessoryStack.hidden = true
			audioLibraryCell.menuButton.hidden = true
		}
	}
}

final class AddToKyoozPlaylistDSD : AddToPlaylistDSD {
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let playlist = sourceData[indexPath] as? KyoozPlaylist else { return }
		var playlistTracks = playlist.tracks
		playlistTracks.appendContentsOf(tracksToAdd)
		do {
			try KyoozPlaylistManager.instance.createOrUpdatePlaylist(playlist, withTracks: playlistTracks)
		} catch let error {
			KyoozUtils.showPopupError(withTitle: "Failed to add \(tracksToAdd.count) tracks to playlist: \(playlist.name)", withThrownError: error, presentationVC: nil)
		}
	}
	
}

final class AddToAppleMusicPlaylistDSD : AddToPlaylistDSD {
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if #available(iOS 9.3, *) {
			guard let playlist = sourceData[indexPath] as? MPMediaPlaylist, items = tracksToAdd as? [MPMediaItem] else { return }
			let status = SKCloudServiceController.authorizationStatus()
			guard status == .Authorized else {
				if status == .NotDetermined {
					SKCloudServiceController.requestAuthorization({ (status) in
						if status == .Authorized {
							playlist.addMediaItems(items, completionHandler: { (error) in
								if let e = error {
									KyoozUtils.showPopupError(withTitle: "Error saving tracks to playlist \(playlist.name ?? "")", withThrownError: e, presentationVC: nil)
								}
							})
						}
					})
				}
				return
			}
			playlist.addMediaItems(items, completionHandler: { (error) in
				if let e = error {
					KyoozUtils.showPopupError(withTitle: "Error saving tracks to playlist \(playlist.name)", withThrownError: e, presentationVC: nil)
				}
			})
		} else {
			KyoozUtils.showPopupError(withTitle: "Unsupported in iOS versions below iOS 9.3", withMessage: "Please upgrade to iOS 9.3 to use this feature", presentationVC: nil)
		}
	}
}
