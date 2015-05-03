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


    @IBOutlet weak var songTitleCollapsedLabel: UILabel!
    @IBOutlet weak var albumArtistAndAlbumTitleCollapsedLabel: UILabel!
    
    @IBOutlet weak var playbackProgressBar: UISlider!
    @IBOutlet weak var totalPlaybackTimeLabel: UILabel!
    @IBOutlet weak var currentPlaybackTimeLabel: UILabel!
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var playPauseCollapsedButton: UIButton!
    
    @IBOutlet weak var nowPlayingCollapsedBar: UIView!
    @IBOutlet weak var playbackProgressCollapsedBar: UIProgressView!
    
    private let queueBasedMusicPlayer = MusicPlayerContainer.queueBasedMusicPlayer
    private let timeDelayInNanoSeconds = Int64(0.5 * Double(NSEC_PER_SEC))
    
    private var playbackProgressTimer:NSTimer?
    private var albumTitleForCurrentAlbumArt:String?
    
    private var playButtonImage:UIImage!
    private var playButtonHighlightedImage:UIImage!
    private var pauseButtonImage:UIImage!
    private var pauseButtonHighlightedImage:UIImage!
    
    typealias KVOContext = UInt8
    private var observationContext = KVOContext()
    
    var expanded:Bool = false {
        didSet{
//            albumArtwork?.hidden = !expanded
        }
    }
    
    //MARK: - FUNCTIONS
    deinit {
        println("deinitializing NowPlayingSummaryViewController")
        self.invalidateTimer(nil)
        self.unregisterForNotifications()
    }
    

    
    @IBAction func commitUpdateOfPlaybackTime(sender: AnyObject) {
        println("committing slider changes")
        queueBasedMusicPlayer.currentPlaybackTime = sender.value
        playbackProgressBar.value = sender.value
        //leave the timer invalidated because changing the value will trigger a notification from the music player
        //causing the view to reload and the timer to be reinitialized
        //this is preferred because we dont want the timer to start until after the seeking to the time has completed
    }

    @IBAction func updatePlaybackTime(sender: UISlider, forEvent event: UIEvent) {
        println("updating slider value")
        invalidateTimer(sender)
        let sliderValue = sender.value
        let remainingPlaybackTime = Float(queueBasedMusicPlayer.nowPlayingItem?.playbackDuration ?? 0.0) - sliderValue
        updatePlaybackProgressBarTimeLabels(currentPlaybackTime: sliderValue, remainingPlaybackTime: remainingPlaybackTime)
    }

    
    @IBAction func skipBackward(sender: AnyObject) {
        queueBasedMusicPlayer.skipBackwards()
        updatePlaybackProgressBar(nil)
    }
    @IBAction func skipForward(sender: AnyObject) {
        queueBasedMusicPlayer.skipForwards()
    }
    
    
    @IBAction func playPauseAction(sender: AnyObject) {
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
        
        self.playButtonImage = playPauseButton.imageForState(UIControlState.Normal)
        self.playButtonHighlightedImage = playPauseButton.imageForState(UIControlState.Highlighted)
        
        self.pauseButtonImage = UIImage(named: "pause_button")
        self.pauseButtonHighlightedImage = UIImage(named: "pause_button_highlighted")
        
        self.reloadData(nil)
        registerForNotifications()
        updateAlphaLevels()
        self.view.addObserver(self, forKeyPath: "frame", options: NSKeyValueObservingOptions.New, context: &self.observationContext)
        self.view.addObserver(self, forKeyPath: "center", options: NSKeyValueObservingOptions.New, context: &self.observationContext)
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
        self.songTitleCollapsedLabel.text = self.songTitleLabel.text
        
        let albumArtist = nowPlayingItem?.albumArtist ?? "To"
        let albumTitle = nowPlayingItem?.albumTitle ?? "Play"
        self.albumArtistAndAlbumTitleLabel.text = (albumArtist + " - " + albumTitle)
        self.albumArtistAndAlbumTitleCollapsedLabel.text = self.albumArtistAndAlbumTitleLabel.text

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
                albumArtImage = ImageContainer.defaultAlbumArtworkImage
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
                self.totalPlaybackTimeLabel.text = MediaItemUtils.zeroTime
                self.currentPlaybackTimeLabel.text = MediaItemUtils.zeroTime
                self.playbackProgressBar.setValue(0.0, animated: false)
                self.playbackProgressCollapsedBar.progress = 0.0
                return
            }
            var currentPlaybackTime = self.queueBasedMusicPlayer.currentPlaybackTime
            var totalPlaybackTime = Float(self.queueBasedMusicPlayer.nowPlayingItem!.playbackDuration)
            var remainingPlaybackTime = totalPlaybackTime - currentPlaybackTime
            
            self.updatePlaybackProgressBarTimeLabels(currentPlaybackTime:currentPlaybackTime, remainingPlaybackTime:remainingPlaybackTime)
            let progress = currentPlaybackTime
            self.playbackProgressBar.setValue(progress, animated: true)
            self.playbackProgressCollapsedBar.setProgress(Float(progress/totalPlaybackTime), animated: true)
        })
    }
    
    func updatePlaybackProgressBarTimeLabels(#currentPlaybackTime:Float, remainingPlaybackTime:Float) {
        totalPlaybackTimeLabel.text = "-" + MediaItemUtils.getTimeRepresentation(remainingPlaybackTime)
        currentPlaybackTimeLabel.text = MediaItemUtils.getTimeRepresentation(currentPlaybackTime)
    }
    
    func updatePlaybackStatus(sender:AnyObject?) {
        if(queueBasedMusicPlayer.musicIsPlaying) {
            self.playPauseButton.setImage(pauseButtonImage, forState: UIControlState.Normal)
            self.playPauseButton.setImage(pauseButtonHighlightedImage, forState: UIControlState.Highlighted)
            self.playPauseCollapsedButton.setImage(pauseButtonImage, forState: UIControlState.Normal)
            self.playPauseCollapsedButton.setImage(pauseButtonHighlightedImage, forState: UIControlState.Highlighted)
        } else {
            self.playPauseButton.setImage(playButtonImage, forState: UIControlState.Normal)
            self.playPauseButton.setImage(playButtonHighlightedImage, forState: UIControlState.Highlighted)
            self.playPauseCollapsedButton.setImage(playButtonImage, forState: UIControlState.Normal)
            self.playPauseCollapsedButton.setImage(playButtonHighlightedImage, forState: UIControlState.Highlighted)
        }
    }
    
    //MARK: - FUNCTIONS: - KVOFunction
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        switch(keyPath) {
        case "frame","center":
            updateAlphaLevels()
        default:
            println("non observed property has changed")
        }
    }
    
    //MARK: - FUNCTIONS: - Private Functions
    
    private func updateAlphaLevels() {
        let frame = self.view.frame
        let maxY = frame.height - RootViewController.nowPlayingViewCollapsedOffset
        let currentY = maxY - (frame.origin.y - RootViewController.nowPlayingViewCollapsedOffset)
        var alphaLevel = (currentY/maxY)
        
        if(alphaLevel > 1.0 || alphaLevel < 0.1) {
            alphaLevel = floor(alphaLevel)
        }
        
        self.albumArtwork.alpha = alphaLevel
        self.nowPlayingCollapsedBar.alpha = (1.0 - alphaLevel)
    }


    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let application = UIApplication.sharedApplication()
        notificationCenter.addObserver(self, selector: "reloadData:",
            name: QueueBasedMusicPlayerUpdate.NowPlayingItemChanged.rawValue, object: queueBasedMusicPlayer)
        notificationCenter.addObserver(self, selector: "reloadData:",
            name: QueueBasedMusicPlayerUpdate.PlaybackStateUpdate.rawValue, object: queueBasedMusicPlayer)
        
        notificationCenter.addObserver(self, selector: "invalidateTimer:",
            name: UIApplicationDidEnterBackgroundNotification, object: application)
        notificationCenter.addObserver(self, selector: "invalidateTimer:",
            name: UIApplicationWillResignActiveNotification, object: application)
        notificationCenter.addObserver(self, selector: "reloadData:",
            name: UIApplicationDidBecomeActiveNotification, object: application)
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

