//
//  AppDelegate.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/10/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    lazy var lastFmScrobbler = LastFmScrobbler.instance
    lazy var window: UIWindow? = UIWindow(frame: UIScreen.mainScreen().bounds)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        ThemeHelper.applyGlobalAppearanceSettings()
        
        window!.rootViewController = ContainerViewController.instance
        window!.makeKeyAndVisible()

        MPMediaLibrary.defaultMediaLibrary().beginGeneratingLibraryChangeNotifications()
        initMainQueueChecking()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        
    }

    func applicationDidEnterBackground(application: UIApplication) {

    }

    func applicationWillEnterForeground(application: UIApplication) {

    }
    

    func applicationDidBecomeActive(application: UIApplication) {
        lastFmScrobbler.initializeScrobbler()
        lastFmScrobbler.submitCachedScrobbles()
    }

    func applicationWillTerminate(application: UIApplication) {
        MPMediaLibrary.defaultMediaLibrary().endGeneratingLibraryChangeNotifications()
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        BackgroundFetchController.instance.performFetchWithCompletionHandler(completionHandler)
    }

}

