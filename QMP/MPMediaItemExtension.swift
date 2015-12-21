//
//  MPMediaItemExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/18/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

extension MPMediaItem : AudioTrack {
    
    var trackTitle:String! { return title }
    var id:UInt64 { return persistentID }
    var albumArtistId:UInt64 { return albumArtistPersistentID }
    var albumId:UInt64 { return albumPersistentID }
    var audioTrackSource:AudioTrackSource { return AudioTrackSource.iPodLibrary }
    
}

public func ==(lhs:MPMediaItem, rhs:MPMediaItem) -> Bool {
    return lhs.persistentID == rhs.persistentID
}