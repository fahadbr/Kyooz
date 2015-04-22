//
//  NowPlayingInfoHelper.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

class NowPlayingInfoHelper {
    
    class var instance : NowPlayingInfoHelper {
        struct Static {
            static let instance:NowPlayingInfoHelper = NowPlayingInfoHelper()
        }
        return Static.instance
    }
    
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.defaultCenter()
    let mpMediaItemPropertyList = Set<NSObject>(arrayLiteral: [
        MPMediaItemPropertyAlbumTitle,
        MPMediaItemPropertyAlbumTrackCount,
        MPMediaItemPropertyAlbumTrackNumber,
        MPMediaItemPropertyArtist,
        MPMediaItemPropertyArtwork,
        MPMediaItemPropertyComposer,
        MPMediaItemPropertyDiscCount,
        MPMediaItemPropertyDiscNumber,
        MPMediaItemPropertyGenre,
        MPMediaItemPropertyPersistentID,
        MPMediaItemPropertyPlaybackDuration,
        MPMediaItemPropertyTitle,
        MPNowPlayingInfoPropertyElapsedPlaybackTime
        ])
    
    func publishNowPlayingInfo(mediaItem: MPMediaItem) {
        var mediaInfoToPublish = Dictionary<NSObject,AnyObject>()
        mediaItem.enumerateValuesForProperties(mpMediaItemPropertyList) { (property:String!, value:AnyObject!, UnsafeMutablePointer) -> Void in
            mediaInfoToPublish[property] = value
        }

        println("publishing now playing info \(mediaInfoToPublish.description)")
        nowPlayingInfoCenter.nowPlayingInfo = mediaInfoToPublish
    }
}

