//
//  AppDelegate.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/10/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {


    let queueBasedMusicPlayer = MusicPlayerContainer.queueBasedMusicPlayer
    let tempDataDAO = TempDataDAO.instance
    let lastFmScrobbler = LastFmScrobbler.instance
    
    var window: UIWindow?
    var timer: NSTimer?
    var backgroundTaskIdentifier:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        let containerViewController = ContainerViewController.instance
        
        window!.rootViewController = containerViewController
        window!.makeKeyAndVisible()
        
        AudioSessionManager.instance.initializeAudioSession()
        lastFmScrobbler.initializeScrobbler()
        ThemeHelper.applyGlobalAppearanceSettings()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        
    }

    func applicationDidEnterBackground(application: UIApplication) {
        if(!isMultiTaskingSupported()) {
            queueBasedMusicPlayer.executePreBackgroundTasks()
            return
        }

        if( !queueBasedMusicPlayer.moreBackgroundTimeIsNeeded() || PlaybackStateManager.instance.otherMusicIsPlaying()) {
            return
        }
        
        timer = NSTimer.scheduledTimerWithTimeInterval(5.0,
            target: self,
            selector: "waitForStagedQueuePromotion:",
            userInfo: nil,
            repeats: true)
        let taskName = "waitForStagedQueuePromotionTask"
        
        Logger.debug("Starting background task: " + taskName)
        backgroundTaskIdentifier = application.beginBackgroundTaskWithName(taskName,
            expirationHandler: { [weak self]() in
            self!.queueBasedMusicPlayer.executePreBackgroundTasks()
            self!.endBackgroundTask()
        })

    }

    func applicationWillEnterForeground(application: UIApplication) {

        if(backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            endBackgroundTask()
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        lastFmScrobbler.initializeScrobbler()
        lastFmScrobbler.submitCachedScrobbles()
    }

    func applicationWillTerminate(application: UIApplication) {
        queueBasedMusicPlayer.executePreBackgroundTasks()
    }
    
    func endBackgroundTask() {
        Logger.debug("Ending background task: " + backgroundTaskIdentifier.description)
        let mainQueue = dispatch_get_main_queue()
        dispatch_async(mainQueue, { [weak self]() -> Void in
            if let uwTimer = self!.timer {
                Logger.debug("Resetting Timer")
                uwTimer.invalidate()
                self!.timer = nil
                UIApplication.sharedApplication().endBackgroundTask(self!.backgroundTaskIdentifier)
                self!.backgroundTaskIdentifier = UIBackgroundTaskInvalid
            }
            
        })
    }
    
    func waitForStagedQueuePromotion(sender: NSTimer) {
        if(!queueBasedMusicPlayer.moreBackgroundTimeIsNeeded() || PlaybackStateManager.instance.otherMusicIsPlaying()) {
            self.endBackgroundTask()
        } else {
            Logger.debug("Staged queue is not yet promoted")
        }
    }

    func isMultiTaskingSupported() -> Bool {
        return UIDevice.currentDevice().multitaskingSupported
    }

}

