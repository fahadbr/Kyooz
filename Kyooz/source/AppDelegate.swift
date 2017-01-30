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

	var window: UIWindow?
    var queueChangeListener: QueueChangeListener!

	func application(_ application: UIApplication,
	                 didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		ThemeHelper.applyGlobalAppearanceSettings()
    
		window = createWindow()
		window!.rootViewController = ContainerViewController.instance
		window!.makeKeyAndVisible()

		MPMediaLibrary.default().beginGeneratingLibraryChangeNotifications()
		initMainQueueChecking()
		ApplicationDefaults.initializeData()
    	queueChangeListener = QueueChangeListener.instance
		return true
	}


    func applicationDidBecomeActive(_ application: UIApplication) {
        lastFmScrobbler.initializeScrobbler()
        lastFmScrobbler.submitCachedScrobbles()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        MPMediaLibrary.default().endGeneratingLibraryChangeNotifications()
    }


    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        BackgroundFetchController.instance.performFetchWithCompletionHandler(completionHandler)
    }

}

extension AppDelegate {

	func createWindow() -> UIWindow {
//		#if MOCK_DATA
//			Logger.debug("starting app with tweaks window")
//			let tweaksGestureRecognizer = UIPinchGestureRecognizer()
//			let window = TweakWindow(frame: UIScreen.main.bounds,
//			                         gestureType: .gesture(tweaksGestureRecognizer),
//			                         tweakStore: KyoozTweaks.defaultStore)
//			KyoozUtils.doInMainQueueAsync() {
//				ContainerViewController.instance.view.addGestureRecognizer(tweaksGestureRecognizer)
//			}
//			return window
//		#else
			return UIWindow(frame: UIScreen.main.bounds)
//		#endif
	}


}
