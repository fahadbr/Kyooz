//
//  AudioEntityTVDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/31/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer


class AudioTrackCollectionDSD : AudioEntityDSD {
	
	func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
		guard !tableView.isEditing else { return }
		
		tableView.deselectRow(at: indexPath, animated: true)
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
    
    func tableView(_ tableView: UITableView, editingStyleForRowAtIndexPath indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    
    func tableView(_ tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let mutableSourceData = sourceData as? MutableAudioEntitySourceData else {
                return
            }
            do {
                let indexPaths = [indexPath]
                try mutableSourceData.deleteEntitiesAtIndexPaths(indexPaths)
                tableView.deleteRows(at: indexPaths, with: .automatic)
            } catch let error {
                KyoozUtils.showPopupError(withTitle: "Could not delete playlist: \((sourceData[indexPath] as? KyoozPlaylist)?.name ?? "Unknown Playlist")", withThrownError: error, presentationVC: nil)
                tableView.isEditing = false
            }

        }
    }
}

/**
* This is an abstract class and will crash the system if used directly
*/
class AddToPlaylistDSD : AudioTrackCollectionDSD {
	
	fileprivate let tracksToAdd:[AudioTrack]
	fileprivate let completion: ( () -> Void )?
	
    init(sourceData:AudioEntitySourceData, reuseIdentifier:String, tracksToAdd:[AudioTrack], completion: ( () -> Void )?) {
		self.tracksToAdd = tracksToAdd
        self.completion = completion
		super.init(sourceData: sourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: nil)
	}
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let libraryCell = cell as? MediaLibraryTableViewCell {
            libraryCell.accessoryStack.isHidden = true
            libraryCell.menuButton.isHidden = true
        }
        return cell
    }

	
}

final class AddToKyoozPlaylistDSD : AddToPlaylistDSD {
	
	override func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
		guard let playlist = sourceData[indexPath] as? KyoozPlaylist else { return }
		var playlistTracks = playlist.tracks
		playlistTracks.append(contentsOf: tracksToAdd)
		do {
			try KyoozPlaylistManager.instance.update(playlist:playlist, withTracks: playlistTracks)
		} catch let error {
			KyoozUtils.showPopupError(withTitle: "Failed to add \(tracksToAdd.count) tracks to playlist: \(playlist.name)", withThrownError: error, presentationVC: nil)
		}
        completion?()
	}
	
}

@available(iOS 9.3, *)
final class AddToAppleMusicPlaylistDSD : AddToPlaylistDSD {
	
	override func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        guard let playlist = sourceData[indexPath] as? MPMediaPlaylist, let items = tracksToAdd as? [MPMediaItem] else { return }
        
        IPodLibraryDAO.addTracksToPlaylist(playlist, tracks: items)
        completion?()
	}

}
