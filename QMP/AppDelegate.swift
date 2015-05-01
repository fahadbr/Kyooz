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
    
    var window: UIWindow?
    var timer: NSTimer?
    var backgroundTaskIdentifier:UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        let containerViewController = ContainerViewController()
        
        window!.rootViewController = containerViewController
        window!.makeKeyAndVisible()
        
        AudioSessionManager.instance.initializeAudioSession()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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
        
        println("Starting background task: " + taskName)
        backgroundTaskIdentifier = application.beginBackgroundTaskWithName(taskName,
            expirationHandler: { [weak self]() in
            self!.queueBasedMusicPlayer.executePreBackgroundTasks()
            self!.endBackgroundTask()
        })
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        

    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        if(backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            endBackgroundTask()
        }
        
        PlaybackStateManager.instance.correctPlaybackState()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        queueBasedMusicPlayer.executePreBackgroundTasks()
    }
    
    func endBackgroundTask() {
        println("Ending background task: " + backgroundTaskIdentifier.description)
        let mainQueue = dispatch_get_main_queue()
        dispatch_async(mainQueue, { [weak self]() -> Void in
            if let uwTimer = self!.timer {
                println("Resetting Timer")
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
            println("Staged queue is not yet promoted")
        }
    }

    func isMultiTaskingSupported() -> Bool {
        return UIDevice.currentDevice().multitaskingSupported
    }

}

