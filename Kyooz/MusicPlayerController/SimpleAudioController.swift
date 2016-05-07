//
//  SimpleAudioController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/23/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import AVFoundation

class SimpleAudioController : NSObject, AudioController, AVAudioPlayerDelegate{
    
    static let instance = SimpleAudioController()
    
    private var scrobbleTime:NSTimeInterval = 0
    
    var avAudioPlayer:AVAudioPlayer? {
        didSet {
            if(avAudioPlayer == nil) { return }
            scrobbleTime = avAudioPlayer!.duration / 2
        }
    }
    
    //MARK: AudioController Protocol items
    var delegate:AudioControllerDelegate!

    var audioTrackIsLoaded:Bool {
        return avAudioPlayer != nil
    }
    
    var canScrobble:Bool {
        if(avAudioPlayer == nil) { return false }
        return currentPlaybackTime >= scrobbleTime
    }
    
    var currentPlaybackTime:Double {
        get {
            if let player = avAudioPlayer {
                return player.currentTime
            }
            return 0.0
        } set {
            if let player = avAudioPlayer {
                player.currentTime = newValue
            }
        }
    }
    
    func play() -> Bool {
        if let audioPlayer = avAudioPlayer {
            audioPlayer.play()
            return true
        }
        return false
    }
    
    func pause() -> Bool {
        if let audioPlayer = avAudioPlayer {
            audioPlayer.pause()
            return true
        }
        return false
    }
    
    func loadItem(url:NSURL) throws {
        avAudioPlayer = try AVAudioPlayer(contentsOfURL: url)

        avAudioPlayer!.delegate = self
        avAudioPlayer!.prepareToPlay()
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        delegate.audioPlayerDidFinishPlaying(self, successfully: flag)
    }
}
