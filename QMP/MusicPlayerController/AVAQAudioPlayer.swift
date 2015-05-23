//
//  AVAQAudioPlayer.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/23/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import AVFoundation

class AVAQAudioPlayer : AudioPlayer {
    
    var delegate:AudioPlayerDelegate?
    
    var audioTrackIsLoaded:Bool {
        return false
    }
    
    var currentPlaybackTime:Double = 1.0
    
    func play() -> Bool {
        return false
    }
    
    func pause() -> Bool {
       return false
    }
    
    func loadItem(url:NSURL) -> Bool {
//        let jj = AudioQueueNewOutput(<#inFormat: UnsafePointer<AudioStreamBasicDescription>#>, <#inCallbackProc: AudioQueueOutputCallback#>, <#inUserData: UnsafeMutablePointer<Void>#>, <#inCallbackRunLoop: CFRunLoop!#>, <#inCallbackRunLoopMode: CFString!#>, <#inFlags: UInt32#>, <#outAQ: UnsafeMutablePointer<AudioQueueRef>#>)
        return true
    }

    
    
}