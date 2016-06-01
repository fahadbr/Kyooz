//
//  KYMediaItem.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/5/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

@objc protocol AudioTrack : AudioEntity {
    
    var albumArtist:String! { get }
    var albumArtistId:UInt64 { get }
    var albumId:UInt64 { get }
    var albumTitle:String! { get }
    var albumTrackNumber:Int { get }
    var assetURL:NSURL! { get }
    var artist:String! { get }
    var id:UInt64 { get }
    var playbackDuration:NSTimeInterval { get }
    var trackTitle:String! { get }
    var audioTrackSource:AudioTrackSource { get }
    var isCloudTrack:Bool { get }
    var genre:String? { get }
    var releaseYear:String? { get }
    var hasArtwork:Bool { get }
    
    func enumerateValuesForProperties(properties: Set<String>!, usingBlock block: ((String, AnyObject, UnsafeMutablePointer<ObjCBool>) -> Void))
    
}

@objc enum AudioTrackSource:Int {
    case iPodLibrary
    case Spotify
}


//extension SPTPartialTrack : AudioTrack {
//    
//    var albumArtist:String! {
//        if(artists == nil || artists.isEmpty) { return "Null" }
//        if let firstArtist = (artists[0] as? SPTPartialArtist)?.name {
//
//            let result = firstArtist.containsIgnoreCase(" feat. ")
//            if(result.doesContain && result.rangeOfString != nil) {
//                return firstArtist.substringToIndex(result.rangeOfString!.startIndex)
//            }
//            return firstArtist
//        }
//        return "Null"
//        
//    }
//    var albumId:UInt64 {
//        
//        return 0
//    }
//    var albumTitle:String! {
//        return album?.name
//    }
//    var albumTrackNumber:Int { return trackNumber }
//    var assetURL:NSURL! { return playableUri }
//    
//    var artist:String! {
//        var artistString = ""
//        if artists == nil { return "Null" }
//        var isFirst = true
//        for artistObj in artists {
//            if let artist = artistObj as? SPTPartialArtist {
//                if(!isFirst) { artistString += ", " }
//                artistString += artist.name
//                
//                isFirst = false
//            }
//        }
//        
//        return artistString
//    }
//    
//    var id:UInt64 { return 0 }
//    var playbackDuration:NSTimeInterval { return duration }
//    var trackTitle:String! { return name }
//    var artwork:MPMediaItemArtwork! { return nil }
//    var audioTrackSource:AudioTrackSource { return AudioTrackSource.Spotify }
//    
//    func enumerateValuesForProperties(properties: Set<NSObject>!, usingBlock block: ((String!, AnyObject!, UnsafeMutablePointer<ObjCBool>) -> Void)!) {
//        
//    }
//    
//}