//
//  File.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class AudioEntityDSD : NSObject, AudioEntityDSDProtocol {
    
    weak var audioCellDelegate:ConfigurableAudioTableCellDelegate?
	weak var parentMediaEntityHeaderVC:ParentMediaEntityHeaderViewController?
    
    var sourceData:AudioEntitySourceData
    var audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    private let reuseIdentifier:String
	
	var hasData:Bool {
		return !sourceData.entities.isEmpty
	}
    
    init(sourceData:AudioEntitySourceData, reuseIdentifier:String, audioCellDelegate:ParentMediaEntityHeaderViewController?) {
        self.sourceData = sourceData
        self.reuseIdentifier = reuseIdentifier
        self.audioCellDelegate = audioCellDelegate
		self.parentMediaEntityHeaderVC = audioCellDelegate
        super.init()
    }
    
    //MARK: - TableView Datasource Methods

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let sections = sourceData.sections.count
        tableView.sectionHeaderHeight = sections > 1 ? 40 : 0
		return sections
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sourceData.sections[section].count
    }
	
	func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        if !sourceData.sectionNamesCanBeUsedAsIndexTitles {
            return nil
        }
        return sourceData.sections.map() { return $0.name }
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
            
            if let nowPlayingItemId = audioQueuePlayer.nowPlayingItem?.persistentIdForGrouping(libraryGrouping), let trackId = entity.representativeTrack?.persistentIdForGrouping(libraryGrouping) where nowPlayingItemId != 0 && trackId != 0 && nowPlayingItemId == trackId {
                audioCell.isNowPlayingItem = true
            } else {
                audioCell.isNowPlayingItem = false
            }
        } else {
            cell.textLabel?.text = entity.representativeTrack?.trackTitle
        }
        
        return cell
        
    }
    
    //MARK: - TableView delegate methods
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SearchResultsHeaderView.reuseIdentifier) as? SearchHeaderFooterView else {
            return nil
        }
        view.initializeHeaderView()
        
        if let headerView = view.headerView {
            headerView.headerTitleLabel.text = sourceData.sections[section].name
            headerView.disclosureContainerView.hidden = true
        }
        return view
    }
	

}