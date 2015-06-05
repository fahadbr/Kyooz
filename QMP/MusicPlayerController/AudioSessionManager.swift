//
//  AudioSessionManager.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import AVFoundation

class AudioSessionManager : NSObject {
    
    class var instance : AudioSessionManager {
        struct Static {
            static let instance:AudioSessionManager = AudioSessionManager()
        }
        return Static.instance
    }
    
    override init() {
        super.init()
        registerForNotifications()
    }
    
    deinit {
        unregisterForNotifications()
    }
    
    private (set) var deviceSampleRate:Double!
    var observationContext = KVOContext()
    
    private let audioSession = AVAudioSession.sharedInstance()
    private let secondaryAudioShouldBeSilencedHint = "secondaryAudioShouldBeSilencedHint"
    
    func initializeAudioSession() {
        Logger.debug("initializing audio session")
        audioSession.setCategory(AVAudioSessionCategoryPlayback, error: NSErrorPointer())
//        audioSession.setActive(true, error: NSErrorPointer())
        deviceSampleRate = audioSession.sampleRate
    }
    
    func handleAudioSessionChange(notification:NSNotification) {
        ApplicationDefaults.audioQueuePlayer.pause()
    }
    
    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()

        notificationCenter.addObserver(self, selector: "handleAudioSessionChange:",
            name: AVAudioSessionInterruptionNotification, object: audioSession)
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
}
