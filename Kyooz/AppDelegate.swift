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
//    lazy var window: UIWindow? = UIWindow(frame: UIScreen.mainScreen().bounds)
//    lazy var window: UIWindow? = TweakWindow(frame: UIScreen.mainScreen().bounds, tweakStore: KyoozTweaks.defaultStore)
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        ThemeHelper.applyGlobalAppearanceSettings()
        
        
        let tweaksGestureRecognizer = UIPinchGestureRecognizer()
        let window = TweakWindow(frame: UIScreen.mainScreen().bounds,
                                 gestureType: .Gesture(tweaksGestureRecognizer),
                                 tweakStore: KyoozTweaks.defaultStore)
        
        let containerVC = ContainerViewController.instance
        window.rootViewController = containerVC
        window.makeKeyAndVisible()
        self.window = window
        
        KyoozUtils.doInMainQueueAsync() {
            containerVC.view.addGestureRecognizer(tweaksGestureRecognizer)
        }

        MPMediaLibrary.defaultMediaLibrary().beginGeneratingLibraryChangeNotifications()
        initMainQueueChecking()
		ApplicationDefaults.initializeData()
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

