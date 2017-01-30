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
    
    func handleAudioSessionChange(_ notification:Notification) {
        ApplicationDefaults.audioQueuePlayer.pause()
    }
    
    private func registerForNotifications() {
        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(self, selector: #selector(AudioSessionManager.handleAudioSessionChange(_:)),
            name: NSNotification.Name.AVAudioSessionInterruption, object: audioSession)
    }
    
    private func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    
}
