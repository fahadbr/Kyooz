//
//  AudioSessionManager.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import AVFoundation

final class AudioSessionManager : NSObject {
    
    static let instance = AudioSessionManager()
    
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
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
        } catch let error as NSError {
            Logger.error("\(error.description)")
        }
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
