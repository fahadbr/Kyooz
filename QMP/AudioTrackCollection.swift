//
//  AudioTrackCollection.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/5/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

protocol AudioTrackCollection {
    
    var tracks:[AudioTrack]! { get }
    var titleForCollection:String! { get }
    
}

enum AudioTrackCollectionGroupingLevel {
    case AlbumArtist
    case Album
}