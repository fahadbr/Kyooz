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
    
    static let instance = NowPlayingInfoHelper()
    
    
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
        MPMediaItemPropertyTitle
        )
    
    func publishNowPlayingInfo(_ mediaItem: AudioTrack, currentIndex: Int, queueCount: Int, elapsedTime: Float = 0) {
        var mediaInfoToPublish = getDictionaryForMediaItem(mediaItem)
        mediaInfoToPublish[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        mediaInfoToPublish[MPNowPlayingInfoPropertyPlaybackQueueIndex] = currentIndex
        mediaInfoToPublish[MPNowPlayingInfoPropertyPlaybackQueueCount] = queueCount
        nowPlayingInfoCenter.nowPlayingInfo = mediaInfoToPublish
    }
    
    private func getDictionaryForMediaItem(_ mediaItem:AudioTrack) -> [String : Any] {
        var mediaInfoToPublish = [String : Any]()
		mediaItem.queryValues(forProperties: mpMediaItemPropertyList) { (property:String, value:Any?, _) -> Void in
            guard let v = value, !(v is NSNull) else { return }
			mediaInfoToPublish[property] = v
		}

        return mediaInfoToPublish
    }
}

