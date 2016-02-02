//
//  AudioEntityTVDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/31/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class AudioCollectionTVDelegate : ParentAudioEntityTVDelegate {
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		let entity = sourceData[indexPath]
		
		guard let filterQuery = (sourceData as? MediaQuerySourceData)?.filterQuery else {
			Logger.error("expected source data to be mediaQuerySourceData object but was not")
			return
		}
		
		//go to specific album track view controller if we are selecting an album collection
		ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(basePredicates:filterQuery.filterPredicates, parentGroup: sourceData.libraryGrouping, entity: entity)
	}
	
}
