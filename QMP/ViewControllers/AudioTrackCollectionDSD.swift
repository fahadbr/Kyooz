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
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
//    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
//        return [UITableViewRowAction(style: .Default, title: "Delete", handler: { [weak self](action, indexPath) -> Void in
//            self?.tableView(tableView, commitEditingStyle: .Delete, forRowAtIndexPath: indexPath)
//        })]
//    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            guard let playlist = sourceData[indexPath] as? KyoozPlaylist, let kyoozPlaylistManager = sourceData as? KyoozPlaylistManager else {
                return
            }
            do {
                try kyoozPlaylistManager.deletePlaylist(playlist)
            } catch let error {
                KyoozUtils.showPopupError(withTitle: "Could not delete playlist \"\(playlist.name)\"", withMessage: "Error Message: \((error as? KyoozErrorProtocol)?.errorDescription ?? "Unknown Error")", presentationVC: ContainerViewController.instance)
                tableView.editing = false
                return
            }
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            if sourceData.entities.count == 0 {
                tableView.deleteSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
                tableView.sectionHeaderHeight = 0
                tableView.estimatedSectionHeaderHeight = 0
                KyoozUtils.doInMainQueueAsync() { [mediaEntityTVC = self.parentMediaEntityHeaderVC] in
                    mediaEntityTVC?.reloadAllData()
                }
            }
        }
    }
    
}
