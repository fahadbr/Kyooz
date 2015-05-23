//
//  AVAPAudioPlayer.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/23/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import AVFoundation

class AVAPAudioPlayer : NSObject, AudioPlayer, AVAudioPlayerDelegate{
    
    static let instance = AVAPAudioPlayer()
    
    var avAudioPlayer:AVAudioPlayer?
    
    //MARK: AudioPlayer Protocol items
    var delegate:AudioPlayerDelegate?

    var audioTrackIsLoaded:Bool {
        return avAudioPlayer != nil
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
    
    func loadItem(url:NSURL) -> Bool {
        var error:NSError?
        avAudioPlayer = AVAudioPlayer(contentsOfURL: url, error: &error)
        if error != nil {
            Logger.debug("Error occured with loading audio for url \(url.description): \(error!.description)")
            return false
        }
        avAudioPlayer!.delegate = self
        avAudioPlayer!.prepareToPlay()
        return true
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        delegate?.audioPlayerDidFinishPlaying(self, successfully: flag)
    }
}
