//
//  AudioPlayer.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/23/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

protocol AudioPlayer {
    
    var currentPlaybackTime:Double { get set }
    var audioTrackIsLoaded:Bool { get }
    var delegate:AudioPlayerDelegate? { get set }
    
    func play() -> Bool
    
    func pause() -> Bool
    
    func loadItem(url:NSURL) -> Bool

}

protocol AudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(player:AudioPlayer, successfully flag:Bool)
    
}