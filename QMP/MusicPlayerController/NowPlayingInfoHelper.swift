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
    let mpMediaItemPropertyList = Set<NSObject>(arrayLiteral:
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
        )
    
    func publishNowPlayingInfo(mediaItem: MPMediaItem) {
        let mediaInfoToPublish = getDictionaryForMediaItem(mediaItem)
        nowPlayingInfoCenter.nowPlayingInfo = mediaInfoToPublish
    }
    
    func updateElapsedPlaybackTime(mediaItem:MPMediaItem, elapsedTime:Float) {
        var mediaInfoToPublish = getDictionaryForMediaItem(mediaItem)
        mediaInfoToPublish[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        nowPlayingInfoCenter.nowPlayingInfo = mediaInfoToPublish
    }
    
    private func getDictionaryForMediaItem(mediaItem:MPMediaItem) -> Dictionary<NSObject, AnyObject> {
        var mediaInfoToPublish = Dictionary<NSObject,AnyObject>()
        mediaItem.enumerateValuesForProperties(mpMediaItemPropertyList) { (property:String!, value:AnyObject!, UnsafeMutablePointer) -> Void in
            mediaInfoToPublish[property] = value
        }
        
//        Logger.debug("publishing now playing info for mediaItem: \(mediaInfoToPublish[MPMediaItemPropertyTitle])")
        return mediaInfoToPublish
    }
}

