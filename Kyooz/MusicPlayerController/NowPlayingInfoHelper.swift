//
//  NowPlayingInfoHelper.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

final class NowPlayingInfoHelper {
    
    class var instance : NowPlayingInfoHelper {
        struct Static {
            static let instance:NowPlayingInfoHelper = NowPlayingInfoHelper()
        }
        return Static.instance
    }
    
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    let mpMediaItemPropertyList = Set<String>(arrayLiteral:
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
    
    func publishNowPlayingInfo(_ mediaItem: AudioTrack) {
        let mediaInfoToPublish = getDictionaryForMediaItem(mediaItem)
        nowPlayingInfoCenter.nowPlayingInfo = mediaInfoToPublish
    }
    
    func updateElapsedPlaybackTime(_ mediaItem:AudioTrack, elapsedTime:Float) {
        var mediaInfoToPublish = getDictionaryForMediaItem(mediaItem)
        mediaInfoToPublish[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        nowPlayingInfoCenter.nowPlayingInfo = mediaInfoToPublish
    }
    
    private func getDictionaryForMediaItem(_ mediaItem:AudioTrack) -> [String:Any] {
        var mediaInfoToPublish = [String:Any]()
		mediaItem.queryValues(forProperties: mpMediaItemPropertyList) { (property:String, value:Any?, _) -> Void in
			mediaInfoToPublish[property] = value
		}

        return mediaInfoToPublish
    }
}

