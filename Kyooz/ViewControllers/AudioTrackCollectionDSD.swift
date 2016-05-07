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
This is an abstract class and will crash the system if used directly
*/
class AddToPlaylistDSD : AudioTrackCollectionDSD {
	
	private let tracksToAdd:[AudioTrack]
    private weak var callbackVC:AddToPlaylistViewController?
    private var playlistTypeName:String {
        return ""
    }
	
    init(sourceData:AudioEntitySourceData, reuseIdentifier:String, tracksToAdd:[AudioTrack], callbackVC:AddToPlaylistViewController) {
		self.tracksToAdd = tracksToAdd
        self.callbackVC = callbackVC
		super.init(sourceData: sourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: nil)
	}
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        if let libraryCell = cell as? MediaLibraryTableViewCell {
            libraryCell.accessoryStack.hidden = true
            libraryCell.menuButton.hidden = true
        }
        return cell
    }
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		fatalError("this is a parent class, must use a subclass")
	}
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableView.rowHeight))
        button.layer.borderColor = UIColor.darkGrayColor().CGColor
        button.layer.borderWidth = 0.5
        if let label = button.titleLabel {
            button.setTitle("NEW \(playlistTypeName)..", forState: .Normal)
            button.setTitleColor(ThemeHelper.defaultFontColor, forState: .Normal)
            button.setTitleColor(ThemeHelper.defaultVividColor, forState: .Highlighted)
            button.backgroundColor = ThemeHelper.defaultTableCellColor
            label.font = ThemeHelper.defaultFont
            label.textAlignment = .Center
        }
        button.addTarget(self, action: #selector(self.showNewPlaylistController), forControlEvents: .TouchUpInside)
        return button
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return ThemeHelper.sidePanelTableViewRowHeight
    }
    
    func showNewPlaylistController() {
		fatalError("this is a parent class, must use a subclass")
    }
	
}

final class AddToKyoozPlaylistDSD : AddToPlaylistDSD {
    
    private override var playlistTypeName:String {
        return "KYOOZ PLAYLIST"
    }
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let playlist = sourceData[indexPath] as? KyoozPlaylist else { return }
		var playlistTracks = playlist.tracks
		playlistTracks.appendContentsOf(tracksToAdd)
		do {
			try KyoozPlaylistManager.instance.createOrUpdatePlaylist(playlist, withTracks: playlistTracks)
		} catch let error {
			KyoozUtils.showPopupError(withTitle: "Failed to add \(tracksToAdd.count) tracks to playlist: \(playlist.name)", withThrownError: error, presentationVC: nil)
		}
        callbackVC?.dismissAddToPlaylistController()
	}
    
    override func showNewPlaylistController() {
        callbackVC?.dismissViewControllerAnimated(true, completion: nil)
        KyoozUtils.showKyoozPlaylistCreationControllerForTracks(tracksToAdd, completionAction: callbackVC?.completionAction)
    }
	
}

@available(iOS 9.3, *)
final class AddToAppleMusicPlaylistDSD : AddToPlaylistDSD {
	
    private override var playlistTypeName:String {
        return "ITUNES PLAYLIST"
    }
    
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let playlist = sourceData[indexPath] as? MPMediaPlaylist, items = tracksToAdd as? [MPMediaItem] else { return }
        
        IPodLibraryDAO.addTracksToPlaylist(playlist, tracks: items)
        callbackVC?.dismissAddToPlaylistController()
	}
    
    override func showNewPlaylistController() {
        callbackVC?.dismissViewControllerAnimated(true, completion: nil)
        KyoozUtils.showITunesPlaylistCreationControllerForTracks(tracksToAdd, completionAction: callbackVC?.completionAction)
    }

}
