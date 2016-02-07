//
//  AudioEntityDSDSectionDelegator.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/3/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class AudioEntityDSDSectionDelegator: NSObject, AudioEntityDSDProtocol {
	
	private let originalOrderedDatasources:[AudioEntityDSDProtocol]
	private var sections:[AudioEntityDSDProtocol] = [AudioEntityDSDProtocol]()
	
	init(datasources:[AudioEntityDSDProtocol]) {
		self.originalOrderedDatasources = datasources
        super.init()
        reloadSections()
	}
    
    var hasData:Bool {
        return !sections.isEmpty
    }
	
    //MARK: - Table View Datasource
    
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		let count = sections.count
        tableView.sectionHeaderHeight = count > 1 ? 40 : 0
        return count
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sections[section].tableView(tableView, numberOfRowsInSection: 0)
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return sections[indexPath.section].tableView(tableView, cellForRowAtIndexPath: indexPath)
	}
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return sections[indexPath.section].tableView?(tableView, canEditRowAtIndexPath: indexPath) ?? false
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        tableView.beginUpdates()
        sections[indexPath.section].tableView?(tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
        reloadSections()
        tableView.endUpdates()
    }
    
    //MARK: - Table View Delegate
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return sections[section].tableView?(tableView, viewForHeaderInSection: 0)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        sections[indexPath.section].tableView?(tableView, didSelectRowAtIndexPath:indexPath)
    }
	
	private func reloadSections() {
		sections = originalOrderedDatasources.filter() {
			return $0.hasData
		}
	}
	
}