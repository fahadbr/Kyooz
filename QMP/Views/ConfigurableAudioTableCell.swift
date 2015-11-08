//
//  ConfigurableAudioTableCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 9/2/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

protocol ConfigurableAudioTableCell {
    
    var isNowPlayingItem:Bool { get set }
    
    func configureCellForItems(entity:MPMediaEntity, mediaGroupingType:MPMediaGrouping)

}

extension MediaCollectionTableViewCell {
    

    

}

extension  AlbumTableViewCell {
    

}