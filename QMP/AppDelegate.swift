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


    let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    let tempDataDAO = TempDataDAO.instance
    let lastFmScrobbler = LastFmScrobbler.instance
    var remoteCommandHandler:RemoteCommandHandler!
    
    
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        ThemeHelper.applyGlobalAppearanceSettings()
        AudioEntitySearchViewController.instance // initializing the search controller here
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        let containerViewController = ContainerViewController.instance
        
        window!.rootViewController = containerViewController
        window!.makeKeyAndVisible()

        MPMediaLibrary.defaultMediaLibrary().beginGeneratingLibraryChangeNotifications()
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
        
        if !Logger.errorLogString.isEmpty {
            let kmvc = KyoozMenuViewController()
            kmvc.menuTitle = "Error logs"
            kmvc.menuDetails = Logger.errorLogString
            
            let clearAction = KyoozMenuAction(title: "CLEAR", image: nil, action: { 
                Logger.errorLogString = ""
            })
            kmvc.addActions([clearAction])
            KyoozUtils.showMenuViewController(kmvc)
        }
        
    }

    func applicationWillTerminate(application: UIApplication) {
        MPMediaLibrary.defaultMediaLibrary().endGeneratingLibraryChangeNotifications()
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        BackgroundFetchController.instance.performFetchWithCompletionHandler(completionHandler)
    }

}

