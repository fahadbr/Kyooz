//
//  AudioEntityTVDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/31/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

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
