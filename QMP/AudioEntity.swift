//
//  AudioEntity.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/5/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

@objc protocol AudioEntity : NSSecureCoding, NSObjectProtocol {
    
    var count:Int { get }
    var representativeTrack:AudioTrack? { get }

    func titleForGrouping(libraryGrouping:LibraryGrouping) -> String?
    
    func persistentIdForGrouping(libraryGrouping:LibraryGrouping) -> UInt64
    
}

@objc protocol AudioTrackCollection : AudioEntity {
    
    var tracks:[AudioTrack] { get }
    
}
