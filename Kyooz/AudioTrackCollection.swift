//
//  AudioTrackCollection.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/29/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

@objc protocol AudioTrackCollection : AudioEntity {
    
    var tracks:[AudioTrack] { get }
    
}

class AudioTrackCollectionDTO : NSObject, AudioTrackCollection {
    static func supportsSecureCoding() -> Bool {
        return false
    }
    
    var count:Int {
        return tracks.count
    }
    
    var representativeTrack:AudioTrack? {
        return tracks.first
    }
    
    var tracks:[AudioTrack] = [AudioTrack]()
    
    init(tracks:[AudioTrack]) {
        self.tracks = tracks
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("initWithCoder is not implemented")
    }
    
    func titleForGrouping(libraryGrouping: LibraryGrouping) -> String? {
        return representativeTrack?.titleForGrouping(libraryGrouping)
    }
    
    
    func persistentIdForGrouping(libraryGrouping:LibraryGrouping) -> UInt64 {
        return representativeTrack?.persistentIdForGrouping(libraryGrouping) ?? 0
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        fatalError("encodeWithCoder is not implemented")
    }
    
    func artworkImage(forSize size: CGSize) -> UIImage? {
        return self.representativeTrack?.artworkImage(forSize: size)
    }
    
    override func valueForKey(key: String) -> AnyObject? {
        return self.representativeTrack?.valueForKey(key)
    }
    
    //overriding this so that collections can be searched by their underlying track properties
    override func valueForUndefinedKey(key: String) -> AnyObject? {
        return self.representativeTrack?.valueForKey(key)
    }
    
}
