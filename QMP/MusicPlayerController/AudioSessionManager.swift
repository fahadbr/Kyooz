//
//  AudioSessionManager.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import AVFoundation

class AudioSessionManager {
    
    class var instance : AudioSessionManager {
        struct Static {
            static let instance:AudioSessionManager = AudioSessionManager()
        }
        return Static.instance
    }
    
    private let audioSession = AVAudioSession.sharedInstance()
    
    func initializeAudioSession() {
        println("initializing audio session")
        self.audioSession.setCategory(AVAudioSessionCategoryPlayback, error: NSErrorPointer())
    }
    
}
