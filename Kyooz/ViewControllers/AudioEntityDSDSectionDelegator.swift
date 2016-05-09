//
//  AudioEntityDSDSectionDelegator.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/3/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class AudioEntityDSDSectionDelegator: NSObject, AudioEntityDSDProtocol {
	
    let originalOrderedDatasources:[AudioEntityDSDProtocol]
    var dsdSections:[AudioEntityDSDProtocol] = [AudioEntityDSDProtocol]()
    
    private let showEmptySections:Bool
    
    var sourceData:AudioEntitySourceData {
        return self
    }
    
	init(datasources:[AudioEntityDSDProtocol], showEmptySections:Bool = false) {
		self.originalOrderedDatasources = datasources
        self.showEmptySections = showEmptySections
        super.init()
        reloadSections()
	}
    
    //do i need to use audioEntityDSDProtocol?
    var hasData:Bool {
        return !dsdSections.isEmpty
    }
    
    var rowLimit = 0
    var rowLimitActive = false
	
    //MARK: - Table View Datasource
    
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		let count = dsdSections.count
        tableView.sectionHeaderHeight = count > 1 ? ThemeHelper.tableViewSectionHeaderHeight : 0
        return count
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dsdSections[section].tableView(tableView, numberOfRowsInSection: 0)
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return dsdSections[indexPath.section].tableView(tableView, cellForRowAtIndexPath: indexPath)
	}
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        tableView.beginUpdates()
        let datasourceDelegate = dsdSections[indexPath.section]
        datasourceDelegate.tableView?(tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
        if !datasourceDelegate.hasData {
            tableView.deleteSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Automatic)
        }
        reloadSections()
        tableView.endUpdates()
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return dsdSections[indexPath.section].tableView?(tableView, editingStyleForRowAtIndexPath: indexPath) ?? .None
    }
    
    //MARK: - Table View Delegate
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return dsdSections[section].tableView?(tableView, viewForHeaderInSection: 0)
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return dsdSections[section].tableView?(tableView, viewForFooterInSection: 0)
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return dsdSections[section].tableView?(tableView, heightForFooterInSection: 0) ?? 0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        dsdSections[indexPath.section].tableView?(tableView, didSelectRowAtIndexPath:indexPath)
    }
	
    func reloadSections() {
        guard !showEmptySections else {
            dsdSections = originalOrderedDatasources
            return
        }
		dsdSections = originalOrderedDatasources.filter() {
			return $0.hasData
		}
	}
	
}

extension AudioEntityDSDSectionDelegator : AudioEntitySourceData {
    
    var sections:[SectionDescription] {
        return dsdSections.map() {
            return $0.sourceData.sections.first ?? SectionDTO(name: "Unknown Section", count: 0)
        }
    }
    
    var entities:[AudioEntity] {
        return dsdSections.flatMap() { return $0.sourceData.entities }
    }
    
    var libraryGrouping:LibraryGrouping {
		return dsdSections.first?.sourceData.libraryGrouping ?? LibraryGrouping.Artists
    }
    
    func reloadSourceData() {
        dsdSections.forEach() { $0.sourceData.reloadSourceData() }
        reloadSections()
    }
    
    func flattenedIndex(indexPath: NSIndexPath) -> Int {
        var offset = 0
        for i in 0...indexPath.section {
            offset += dsdSections[i].sourceData.sections.first?.count ?? 0
        }
        return offset + indexPath.row
    }
    
    func getTracksAtIndex(indexPath: NSIndexPath) -> [AudioTrack] {
        return dsdSections[indexPath.section].sourceData.getTracksAtIndex(convertIndexPath(indexPath))
    }
    
    func sourceDataForIndex(indexPath: NSIndexPath) -> AudioEntitySourceData? {
        return dsdSections[indexPath.section].sourceData.sourceDataForIndex(convertIndexPath(indexPath))
    }
    
    subscript(i:NSIndexPath) -> AudioEntity {
        return dsdSections[i.section].sourceData[convertIndexPath(i)]
    }
    
    private func convertIndexPath(indexPath:NSIndexPath) -> NSIndexPath {
        return NSIndexPath(forRow: indexPath.row, inSection: 0)
    }
    
}