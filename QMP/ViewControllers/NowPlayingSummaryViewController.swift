//
//  NowPlayingSummaryViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 4/11/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class NowPlayingSummaryViewController: UIViewController {
    //MARK: - PROPERTIES
    @IBOutlet weak var albumArtwork: UIImageView!
    @IBOutlet weak var albumArtistAndAlbumTitleLabel: UILabel!
    @IBOutlet weak var songTitleLabel: UILabel!

    @IBOutlet weak var playbackProgressBar: UISlider!
    @IBOutlet weak var totalPlaybackTimeLabel: UILabel!
    @IBOutlet weak var currentPlaybackTimeLabel: UILabel!
    
    
    private let queueBasedMusicPlayer = MusicPlayerContainer.queueBasedMusicPlayer
    private let zeroTime = "0:00"
    private let timeDelayInNanoSeconds = Int64(0.5 * Double(NSEC_PER_SEC))
    
    private var playPauseButtonIndex:Int?
    private var playbackProgressTimer:NSTimer?
    private var playBarButtonItem:UIBarButtonItem!
    private var pauseBarButtonItem:UIBarButtonItem!
    
    private var albumTitleForCurrentAlbumArt:String?
    
    //MARK: - FUNCTIONS
    deinit {
        println("deinitializing NowPlayingSummaryViewController")
        invalidateTimer(nil)
        unregisterForNotifications()
    }
    
    @IBAction func unwindToSummaryScreen(segue : UIStoryboardSegue)  {
        reloadData(nil)
    }
    
    //TODO: - ADD THESE FUNCTIONS TO THE INTERFACE
    @IBAction func updatePlaybackTime(sender: UISlider, forEvent event: UIEvent) {
        if(queueBasedMusicPlayer.nowPlayingItem != nil) {
            MusicPlayerContainer.defaultMusicPlayerController.currentPlaybackTime = Double(sender.value)
        }
        updatePlaybackProgressBar(nil)
    }

    
    @IBAction func skipBackward(sender: AnyObject) {
        if(queueBasedMusicPlayer.currentPlaybackTime < 2.0) {
            MusicPlayerContainer.defaultMusicPlayerController.skipToPreviousItem()
        } else {
            MusicPlayerContainer.defaultMusicPlayerController.skipToBeginning()
            updatePlaybackProgressBar(nil)
        }
    }
    @IBAction func skipForward(sender: AnyObject) {
        MusicPlayerContainer.defaultMusicPlayerController.skipToNextItem()
    }
    
    
    @IBAction func playPauseAction(sender: UIBarButtonItem) {
        if(queueBasedMusicPlayer.musicIsPlaying) {
            self.queueBasedMusicPlayer.pause()
        } else {
            self.queueBasedMusicPlayer.play()
        }
    }
    
    //MARK: - FUNCTIONS: - Overridden functions
    override func viewDidLoad() {
        super.viewDidLoad()
        var i = 0
        
        self.playBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Play, target: self, action: "playPauseAction:")
        self.pauseBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Pause, target: self, action: "playPauseAction:")

        for buttonItem in self.toolbarItems! {
            if((buttonItem as! UIBarButtonItem).title == "PP") {
                println("setting playPauseButtonIndex as \(i)")
                self.playPauseButtonIndex = i
            }
            i++
        }
        
        
        self.reloadData(nil)
        registerForNotifications()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        invalidateTimer(nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        invalidateTimer(nil)
    }
    
    func reloadData(notification:NSNotification?) {
        var nowPlayingItem = queueBasedMusicPlayer.nowPlayingItem;
        self.songTitleLabel.text = nowPlayingItem?.title ?? "Nothing"
        let albumArtist = nowPlayingItem?.albumArtist ?? "To"
        let albumTitle = nowPlayingItem?.albumTitle ?? "Play"
        self.albumArtistAndAlbumTitleLabel.text = (albumArtist + " - " + albumTitle)
        
        let artwork = nowPlayingItem?.artwork
        var albumArtTitle:String!
        if(artwork == nil) {
            albumArtTitle = "noArtwork"
        } else {
            albumArtTitle = albumTitle
        }
        
        if(albumTitleForCurrentAlbumArt == nil || albumTitleForCurrentAlbumArt! != albumArtTitle) {
            println("loading new album art image")
            var albumArtImage = artwork?.imageWithSize(CGSize(width: self.albumArtwork.frame.width, height: self.albumArtwork.frame.height))
            if(albumArtImage == nil) {
                albumArtImage = UIImage(named: "headphones")
            }
            self.albumArtwork.image = albumArtImage
            self.view.backgroundColor = UIColor(patternImage: albumArtImage!)
            self.albumTitleForCurrentAlbumArt = albumArtTitle
        }
        
        self.playbackProgressBar.maximumValue = Float(nowPlayingItem?.playbackDuration ?? 1.0)
        updatePlaybackProgressBar(nil)
        updatePlaybackProgressTimer()
        updatePlaybackStatus(nil)
    }
    
    func updatePlaybackProgressTimer() {
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, timeDelayInNanoSeconds)
        let queue = dispatch_get_main_queue()
        dispatch_after(dispatchTime, queue, { [weak self] ()  in
            if(self == nil) {
                return
            }
            if(self!.queueBasedMusicPlayer.musicIsPlaying && self!.playbackProgressTimer == nil) {
                println("initiating playbackProgressTimer")
                self!.playbackProgressTimer = NSTimer.scheduledTimerWithTimeInterval(1.0,
                    target: self!,
                    selector: "updatePlaybackProgressBar:",
                    userInfo: nil,
                    repeats: true)
            } else if(!self!.queueBasedMusicPlayer.musicIsPlaying && self!.playbackProgressTimer != nil){
                self!.invalidateTimer(nil)
            }
        })
    }
    
    func invalidateTimer(sender:AnyObject?) {
        if let uwTimer = self.playbackProgressTimer {
            println("resetting playbackProgressTimer")
            uwTimer.invalidate()
            self.playbackProgressTimer = nil
        }

    }
    
    func updatePlaybackProgressBar(sender:NSTimer?) {
        dispatch_async(dispatch_get_main_queue(), { [unowned self]() in
            if(self.queueBasedMusicPlayer.nowPlayingItem == nil) {
                self.totalPlaybackTimeLabel.text = self.zeroTime
                self.currentPlaybackTimeLabel.text = self.zeroTime
                self.playbackProgressBar.setValue(0.0, animated: false)
                return
            }
            
            var currentPlaybackTime = self.queueBasedMusicPlayer.currentPlaybackTime
            var totalPlaybackTime = self.queueBasedMusicPlayer.nowPlayingItem!.playbackDuration
            var remainingPlaybackTime = totalPlaybackTime - currentPlaybackTime
            
            self.totalPlaybackTimeLabel.text = "-" + self.getTimeRepresentation(remainingPlaybackTime)
            self.currentPlaybackTimeLabel.text = self.getTimeRepresentation(currentPlaybackTime)
            self.playbackProgressBar.setValue(Float(currentPlaybackTime), animated: false)
        })
    }
    
    func updatePlaybackStatus(sender:AnyObject?) {
        if(queueBasedMusicPlayer.musicIsPlaying) {
            self.toolbarItems![playPauseButtonIndex!] = pauseBarButtonItem
        } else {
            self.toolbarItems![playPauseButtonIndex!] = playBarButtonItem
        }
    }
    
    //MARK: - FUNCITONS: - Private Functions
    private func getTimeRepresentation(timevalue:NSTimeInterval) ->  String {
        if(timevalue == Double.NaN || timevalue < 1) {
            return self.zeroTime
        }
        
        var min:String = (Int(timevalue)/60).description
        var secValue = Int(timevalue)%60
        var sec:String!
        if(secValue < 10) {
            sec = "0" + secValue.description
        } else {
            sec = secValue.description
        }
        
        return min + ":" + sec
    }


    private func registerForNotifications() {
        let musicPlayer = MusicPlayerContainer.defaultMusicPlayerController
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let application = UIApplication.sharedApplication()
        
        notificationCenter.addObserver(self, selector: "reloadData:",
            name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification, object: musicPlayer)
        notificationCenter.addObserver(self, selector: "reloadData:",
            name:MPMusicPlayerControllerPlaybackStateDidChangeNotification, object: musicPlayer)
        
        notificationCenter.addObserver(self, selector: "reloadData:",
            name:PlaybackStateManager.PlaybackStateCorrectedNotification, object: PlaybackStateManager.instance)
        
        notificationCenter.addObserver(self, selector: "invalidateTimer:",
            name: UIApplicationDidEnterBackgroundNotification, object: application)
        notificationCenter.addObserver(self, selector: "invalidateTimer:",
            name: UIApplicationWillResignActiveNotification, object: application)
        notificationCenter.addObserver(self, selector: "reloadData:",
            name: UIApplicationDidBecomeActiveNotification, object: application)
        
        musicPlayer.beginGeneratingPlaybackNotifications()
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Navigation


    

}
