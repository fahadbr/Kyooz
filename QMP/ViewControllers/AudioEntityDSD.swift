//
//  File.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class AudioEntityDSD : AudioEntityTableViewDelegate, AudioEntityDSDProtocol {
    
    weak var audioCellDelegate:ConfigurableAudioTableCellDelegate?
	weak var parentMediaEntityHeaderVC:ParentMediaEntityHeaderViewController?
    
    var audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    private let reuseIdentifier:String
	
	var hasData:Bool {
		return !sourceData.entities.isEmpty
	}
    
    var rowLimit:Int = 0
    var rowLimitActive:Bool = false
    
    init(sourceData:AudioEntitySourceData, reuseIdentifier:String, audioCellDelegate:ConfigurableAudioTableCellDelegate?) {
        self.reuseIdentifier = reuseIdentifier
        self.audioCellDelegate = audioCellDelegate
		self.parentMediaEntityHeaderVC = audioCellDelegate as? ParentMediaEntityHeaderViewController
        super.init(sourceData: sourceData)
    }
    
    //MARK: - TableView Datasource Methods

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let sections = sourceData.sections.count
        tableView.sectionHeaderHeight = sections > 1 ? ThemeHelper.tableViewSectionHeaderHeight : 0
		return sections
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = sourceData.sections[section].count

        return rowLimitActive ? min(count, rowLimit) : count
    }
	
	func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        if !sourceData.sectionNamesCanBeUsedAsIndexTitles {
            return nil
        }
        return sourceData.sections.map() { $0.name }
	}
	
	func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
		KyoozUtils.doInMainQueueAsync() { [weak self] in self?.parentMediaEntityHeaderVC?.synchronizeOffsetWithScrollview(tableView) }
		return index
	}
    
    final func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) else {
            return UITableViewCell()
        }
        
        let entity = sourceData[indexPath]
        let libraryGrouping = sourceData.libraryGrouping
        
        if let audioCell = cell as? ConfigurableAudioTableCell {
            audioCell.configureCellForItems(entity, libraryGrouping: libraryGrouping)
            audioCell.indexPath = indexPath
            audioCell.delegate = audioCellDelegate
            audioCell.isNowPlaying = entityIsNowPlaying(entity, libraryGrouping: libraryGrouping, indexPath: indexPath)
        } else {
            cell.textLabel?.text = entity.titleForGrouping(libraryGrouping)
        }
        
        return cell
        
    }
    
    func entityIsNowPlaying(entity:AudioEntity, libraryGrouping:LibraryGrouping, indexPath:NSIndexPath) -> Bool {
        if let nowPlayingItemId = audioQueuePlayer.nowPlayingItem?.persistentIdForGrouping(libraryGrouping), let trackId = entity.representativeTrack?.persistentIdForGrouping(libraryGrouping) where nowPlayingItemId != 0 && trackId != 0 && nowPlayingItemId == trackId {
            return true
        }
        return false
    }

}