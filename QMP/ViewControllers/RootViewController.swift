//
//  RootViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/15/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class RootViewController: UIViewController {
    
    


    
    @IBAction func unwindToBrowser(segue : UIStoryboardSegue)  {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        nowPlayingItem.title = MusicPlayerContainer.applicationMusicPlayer().nowPlayingItem.title
        // Do any additional setup after loading the view.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleNowPlayingItemChanged(notification:NSNotification) {
//        nowPlayingItem.title = MusicPlayerContainer.applicationMusicPlayer().nowPlayingItem.title
    }
    
    func handlePlaybackStateChanged(notification:NSNotification) {


    }
    
    private func registerForMediaPlayerNotifications() {
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleNowPlayingItemChanged:",
//            name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification,
//            object: MusicPlayerContainer.applicationMusicPlayer())
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handlePlaybackStateChanged:",
//            name:MPMusicPlayerControllerPlaybackStateDidChangeNotification,
//            object: MusicPlayerContainer.applicationMusicPlayer())
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handlePlaybackStateChanged:",
//            name:PlaybackStateManager.instance.PlaybackStateCorrectedNotification,
//            object: PlaybackStateManager.instance)
//        MusicPlayerContainer.applicationMusicPlayer().beginGeneratingPlaybackNotifications()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    

}
