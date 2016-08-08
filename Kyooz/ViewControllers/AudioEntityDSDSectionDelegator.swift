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
    
	func numberOfSections(in tableView: UITableView) -> Int {
		let count = dsdSections.count
        tableView.sectionHeaderHeight = count > 1 ? ThemeHelper.tableViewSectionHeaderHeight : 0
        return count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dsdSections[section].tableView(tableView, numberOfRowsInSection: 0)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return dsdSections[(indexPath as NSIndexPath).section].tableView(tableView, cellForRowAt: indexPath)
	}
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        tableView.beginUpdates()
        let datasourceDelegate = dsdSections[(indexPath as NSIndexPath).section]
        datasourceDelegate.tableView?(tableView, commit: editingStyle, forRowAt: indexPath)
        if !datasourceDelegate.hasData {
            tableView.deleteSections(IndexSet(integer: (indexPath as NSIndexPath).section), with: .automatic)
        }
        reloadSections()
        tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return dsdSections[(indexPath as NSIndexPath).section].tableView?(tableView, editingStyleForRowAt: indexPath) ?? .none
    }
    
    //MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return dsdSections[section].tableView?(tableView, viewForHeaderInSection: 0)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return dsdSections[section].tableView?(tableView, viewForFooterInSection: 0)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return dsdSections[section].tableView?(tableView, heightForFooterInSection: 0) ?? 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dsdSections[(indexPath as NSIndexPath).section].tableView?(tableView, didSelectRowAt:indexPath)
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
    
    var tracks:[AudioTrack] {
        return dsdSections.flatMap() { return $0.sourceData.tracks }
    }
    
    var libraryGrouping:LibraryGrouping {
		return dsdSections.first?.sourceData.libraryGrouping ?? LibraryGrouping.Artists
    }
	
	var parentGroup:LibraryGrouping? {
		return nil
	}
	
	var parentCollection:AudioTrackCollection? {
		return nil
	}
    
    func reloadSourceData() {
        dsdSections.forEach() { $0.sourceData.reloadSourceData() }
        reloadSections()
    }
    
    func flattenedIndex(_ indexPath: IndexPath) -> Int {
        var offset = 0
        for i in 0...(indexPath as NSIndexPath).section {
            offset += dsdSections[i].sourceData.sections.first?.count ?? 0
        }
        return offset + (indexPath as NSIndexPath).row
    }
    
    func getTracksAtIndex(_ indexPath: IndexPath) -> [AudioTrack] {
        return dsdSections[(indexPath as NSIndexPath).section].sourceData.getTracksAtIndex(convertIndexPath(indexPath))
    }
    
    func sourceDataForIndex(_ indexPath: IndexPath) -> AudioEntitySourceData? {
        return dsdSections[(indexPath as NSIndexPath).section].sourceData.sourceDataForIndex(convertIndexPath(indexPath))
    }
    
    subscript(i:IndexPath) -> AudioEntity {
        return dsdSections[(i as NSIndexPath).section].sourceData[convertIndexPath(i)]
    }
    
    private func convertIndexPath(_ indexPath:IndexPath) -> IndexPath {
        return IndexPath(row: (indexPath as NSIndexPath).row, section: 0)
    }
    
}
