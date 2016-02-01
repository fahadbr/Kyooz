//
//  File.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class AudioEntityTVDataSource : NSObject, UITableViewDataSource {
    
    weak var audioCellDelegate:ConfigurableAudioTableCellDelegate?
    
    private var sourceData:AudioEntitySourceData
    private var audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    private let reuseIdentifier:String
    
    init(sourceData:AudioEntitySourceData, reuseIdentifier:String, audioCellDelegate:ConfigurableAudioTableCellDelegate?) {
        self.sourceData = sourceData
        self.reuseIdentifier = reuseIdentifier
        self.audioCellDelegate = audioCellDelegate
        super.init()
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sourceData.numberOfSections
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sourceData.numberOfItemsInSection(section)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) else {
            return UITableViewCell()
        }
        
        let entity = sourceData[indexPath]
        let libraryGrouping = sourceData.libraryGrouping
        
        if let audioCell = cell as? ConfigurableAudioTableCell {
            audioCell.configureCellForItems(entity, libraryGrouping: libraryGrouping)
            audioCell.indexPath = indexPath
            audioCell.delegate = audioCellDelegate
            
            if let nowPlayingItemId = audioQueuePlayer.nowPlayingItem?.persistentIdForGrouping(libraryGrouping), let trackId = entity.representativeTrack?.persistentIdForGrouping(libraryGrouping) where nowPlayingItemId == trackId {
                audioCell.isNowPlayingItem = true
            } else {
                audioCell.isNowPlayingItem = false
            }
        } else {
            cell.textLabel?.text = entity.representativeTrack?.trackTitle
        }
        
        return cell
        
    }
}