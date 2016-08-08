//
//  File.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class AudioEntityDSD : NSObject, AudioEntityDSDProtocol, UITableViewDataSource, UITableViewDelegate {
    
    weak var audioCellDelegate:AudioTableCellDelegate?
    weak var scrollViewDelegate:UIScrollViewDelegate?
    
	var audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
	
	var hasData:Bool {
		return !sourceData.entities.isEmpty
	}
	
    var rowLimit:Int = 0
    var rowLimitActive:Bool = false
    var sourceData:AudioEntitySourceData
    
	var useSmallFont:Bool = false
    
	
	private let reuseIdentifier:String
	private lazy var smallFont = ThemeHelper.smallFontForStyle(.bold)
    
    init(sourceData:AudioEntitySourceData, reuseIdentifier:String, audioCellDelegate:AudioTableCellDelegate?) {
        self.reuseIdentifier = reuseIdentifier
        self.audioCellDelegate = audioCellDelegate
        self.scrollViewDelegate = audioCellDelegate as? UIScrollViewDelegate
        self.sourceData = sourceData
        super.init()
    }
    
    //MARK: - TableView Datasource Methods

    func numberOfSections(in tableView: UITableView) -> Int {
        let sections = sourceData.sections.count
        tableView.sectionHeaderHeight = sections > 1 ? ThemeHelper.tableViewSectionHeaderHeight : 0
		return sections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = sourceData.sections[section].count

        return rowLimitActive ? min(count, rowLimit) : count
    }
	
	func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if !sourceData.sectionNamesCanBeUsedAsIndexTitles {
            return nil
        }
        return sourceData.sections.map() { $0.name }
	}
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) else {
            return UITableViewCell()
        }
        
        let entity = sourceData[indexPath]
        let libraryGrouping = sourceData.libraryGrouping
        
        if let audioCell = cell as? AudioTableCellProtocol {
            audioCell.configureCellForItems(entity, libraryGrouping: libraryGrouping)
            audioCell.delegate = audioCellDelegate
            audioCell.isNowPlaying = entityIsNowPlaying(entity, libraryGrouping: libraryGrouping, indexPath: indexPath)
        } else {
            cell.textLabel?.text = entity.titleForGrouping(libraryGrouping)
        }
		
		if useSmallFont {
			(cell as? MediaLibraryTableViewCell)?.titleLabel.font = smallFont
		}
		
        return cell
        
    }
    
    func entityIsNowPlaying(_ entity:AudioEntity, libraryGrouping:LibraryGrouping, indexPath:IndexPath) -> Bool {
        if let nowPlayingItemId = audioQueuePlayer.nowPlayingItem?.persistentIdForGrouping(libraryGrouping),
            let trackId = entity.representativeTrack?.persistentIdForGrouping(libraryGrouping)
            where nowPlayingItemId != 0 && trackId != 0 && nowPlayingItemId == trackId {
            
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: KyoozSectionHeaderView.reuseIdentifier) as? KyoozSectionHeaderView else {
            return nil
        }
        
        headerView.headerTitleLabel.text = sourceData.sections[section].name
        return headerView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    override func isEqual(_ object: AnyObject?) -> Bool {
        guard object == nil else {
            return false
        }
        return self === object!
    }

}
