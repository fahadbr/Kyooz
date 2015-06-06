//
//  KYMediaItem.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/5/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

@objc protocol AudioTrack : AnyObject {
    
    var albumArtist:String! { get }
    var albumId:UInt64 { get }
    var albumTitle:String! { get }
    var albumTrackNumber:Int { get }
    var assetURL:NSURL! { get }
    var artist:String! { get }
    var id:UInt64 { get }
    var playbackDuration:NSTimeInterval { get }
    var trackTitle:String! { get }
    var artwork:MPMediaItemArtwork! { get }
    
    func enumerateValuesForProperties(properties: Set<NSObject>!, usingBlock block: ((String!, AnyObject!, UnsafeMutablePointer<ObjCBool>) -> Void)!)
    
}

extension MPMediaItem : AudioTrack {
    
    var trackTitle:String! { return title }
    var id:UInt64 { return persistentID }
    var albumId:UInt64 { return albumPersistentID }
    
}