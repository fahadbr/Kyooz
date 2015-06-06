//
//  PlaybackStateDTO.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 1/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

class PlaybackStateDTO {
    let musicIsPlaying:Bool
    let nowPlayingItem:AudioTrack?
    let nowPlayingIndex:Int?
    let currentPlaybackTime:NSTimeInterval?
    
    var description : String {
        return "PlaybackStateDTO: musicIsPlaying:\(musicIsPlaying), nowPlayingItem:\(getMediaItemDescription(nowPlayingItem))"
            + ",nowPlayingIndex:\(nowPlayingIndex)"
    }
    
    init(musicIsPlaying:Bool, nowPlayingItem:AudioTrack?, nowPlayingIndex:Int?, currentPlaybackTime:NSTimeInterval?) {
        self.musicIsPlaying = musicIsPlaying
        self.nowPlayingItem = nowPlayingItem
        self.nowPlayingIndex = nowPlayingIndex
        self.currentPlaybackTime = currentPlaybackTime
    }
    

    
    private func getMediaItemDescription(mediaItem:AudioTrack?) -> String {
        if(mediaItem != nil) {
            return mediaItem!.trackTitle + " Artist:" + mediaItem!.albumArtist
        } else {
            return "null"
        }
    }
    
}