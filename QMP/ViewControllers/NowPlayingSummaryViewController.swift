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
    
    @IBOutlet weak var playPauseButton: PlayPauseButtonView!
    @IBOutlet weak var playPauseCollapsedButton: PlayPauseButtonView!
    
    @IBOutlet weak var nowPlayingCollapsedBar: UIView!
    @IBOutlet weak var playbackProgressCollapsedBar: UIProgressView!
    
    @IBOutlet weak var repeatButton: RepeatButtonView!
    @IBOutlet weak var shuffleButton: ShuffleButtonView!
    
    private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    private let timeDelayInNanoSeconds = Int64(0.5 * Double(NSEC_PER_SEC))
    
    private var playbackProgressTimer:NSTimer?
    private var albumIdForCurrentAlbumArt:UInt64?
    
    typealias KVOContext = UInt8
    private var observationContext = KVOContext()
    
    var expanded:Bool = false {
        didSet{
            albumArtwork?.hidden = !expanded
        }
    }
    
    //MARK: - FUNCTIONS
    deinit {
        Logger.debug("deinitializing NowPlayingSummaryViewController")
        self.invalidateTimer(nil)
        self.unregisterForNotifications()
    }
    
    @IBAction func newPlayButtonPressed(sender: AnyObject) {
        Logger.debug("play button pressed")
    }

    
    @IBAction func commitUpdateOfPlaybackTime(sender: UISlider) {
        audioQueuePlayer.currentPlaybackTime = sender.value
        playbackProgressBar.value = sender.value
        playbackProgressCollapsedBar.progress = sender.value
        //leave the timer invalidated because changing the value will trigger a notification from the music player
        //causing the view to reload and the timer to be reinitialized
        //this is preferred because we dont want the timer to start until after the seeking to the time has completed
    }

    @IBAction func updatePlaybackTime(sender: UISlider, forEvent event: UIEvent) {
        invalidateTimer(sender)
        let sliderValue = sender.value
        let remainingPlaybackTime = Float(audioQueuePlayer.nowPlayingItem?.playbackDuration ?? 0.0) - sliderValue
        updatePlaybackProgressBarTimeLabels(currentPlaybackTime: sliderValue, remainingPlaybackTime: remainingPlaybackTime)
    }

    
    @IBAction func skipBackward(sender: AnyObject) {
        audioQueuePlayer.skipBackwards()
        updatePlaybackProgressBar(nil)
    }
    @IBAction func skipForward(sender: AnyObject) {
        audioQueuePlayer.skipForwards()
    }
    
    
    @IBAction func playPauseAction(sender: AnyObject) {
        if(audioQueuePlayer.musicIsPlaying) {
            self.audioQueuePlayer.pause()
        } else {
            self.audioQueuePlayer.play()
        }
    }
    
    @IBAction func toggleShuffle(sender: AnyObject) {
        let newState = !audioQueuePlayer.shuffleActive
        audioQueuePlayer.shuffleActive = newState
        shuffleButton.isActive = audioQueuePlayer.shuffleActive
    }
    
    @IBAction func switchRepeatMode(sender: AnyObject) {
        let newState = audioQueuePlayer.repeatMode.nextState
        audioQueuePlayer.repeatMode = newState
        repeatButton.repeatState = audioQueuePlayer.repeatMode
    }
    
    @IBAction func showQueue(sender: AnyObject) {
        ContainerViewController.instance.toggleSidePanel()
    }
    
    
    @IBAction func goToArtist(sender: AnyObject) {
        if let nowPlayingItem = audioQueuePlayer.nowPlayingItem as? MPMediaItem {
            ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(basePredicates: nil, parentGroup: LibraryGrouping.Artists, entity: nowPlayingItem)
        }
    }
    @IBAction func goToAlbum(sender: AnyObject) {
        if let nowPlayingItem = audioQueuePlayer.nowPlayingItem as? MPMediaItem {
            ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(basePredicates: nil, parentGroup: LibraryGrouping.Albums, entity: nowPlayingItem)
        }
    }
    
    @IBAction func collapseViewController(sender: AnyObject) {
        RootViewController.instance.animatePullablePanel(shouldExpand: false)
    }
    
    //MARK: - FUNCTIONS: - Overridden functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reloadData(nil)
        registerForNotifications()
        
        albumArtwork.layer.shadowOpacity = 0.7
        albumArtwork.layer.shadowOffset = CGSize(width: 0, height: 3)
        albumArtwork.layer.shadowRadius = 10
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
        if(UIApplication.sharedApplication().applicationState != UIApplicationState.Active) { return }
        
        let nowPlayingItem = audioQueuePlayer.nowPlayingItem;
        self.songTitleLabel.text = nowPlayingItem?.trackTitle ?? "Nothing"
        self.songTitleCollapsedLabel.text = self.songTitleLabel.text
        
        let albumArtist = nowPlayingItem?.albumArtist ?? "To"
        let albumTitle = nowPlayingItem?.albumTitle ?? "Play"
        self.albumArtistAndAlbumTitleLabel.text = (albumArtist + " - " + albumTitle)
        self.albumArtistAndAlbumTitleCollapsedLabel.text = self.albumArtistAndAlbumTitleLabel.text

        let artwork = nowPlayingItem?.artwork
        let albumArtId:UInt64
        if(artwork == nil) {
            albumArtId = 0
        } else {
            albumArtId = nowPlayingItem!.albumId
        }
        
        if(albumIdForCurrentAlbumArt == nil || albumIdForCurrentAlbumArt! != albumArtId) {
            Logger.debug("loading new album art image")
            var albumArtImage = artwork?.imageWithSize(albumArtwork.frame.size)
            if(albumArtImage == nil) {
                albumArtImage = ImageContainer.defaultAlbumArtworkImage
            }
            self.albumArtwork.image = albumArtImage
            self.view.backgroundColor = UIColor(patternImage: albumArtImage!)
            self.albumIdForCurrentAlbumArt = albumArtId
        }
        
        self.playbackProgressBar.maximumValue = Float(nowPlayingItem?.playbackDuration ?? 1.0)
        
        repeatButton.repeatState = audioQueuePlayer.repeatMode
        shuffleButton.isActive = audioQueuePlayer.shuffleActive
        
        updatePlaybackProgressBar(nil)
        updatePlaybackProgressTimer()
        updatePlaybackStatus(nil)
    }
    
    @IBAction func updatePlaybackProgressTimer() {
        if(audioQueuePlayer.musicIsPlaying && playbackProgressTimer == nil) {
            Logger.debug("initiating playbackProgressTimer")
            playbackProgressTimer = NSTimer.scheduledTimerWithTimeInterval(1.0,
                target: self,
                selector: "updatePlaybackProgressBar:",
                userInfo: nil,
                repeats: true)
        } else if(!audioQueuePlayer.musicIsPlaying && playbackProgressTimer != nil){
            invalidateTimer(nil)
        }
    }
    
    func invalidateTimer(sender:AnyObject?) {
        if let uwTimer = self.playbackProgressTimer {
            Logger.debug("resetting playbackProgressTimer")
            uwTimer.invalidate()
            self.playbackProgressTimer = nil
        }

    }
    
    func updatePlaybackProgressBar(sender:NSTimer?) {
        dispatch_async(dispatch_get_main_queue(), { [unowned self]() in
            if(self.audioQueuePlayer.nowPlayingItem == nil) {
                self.totalPlaybackTimeLabel.text = MediaItemUtils.zeroTime
                self.currentPlaybackTimeLabel.text = MediaItemUtils.zeroTime
                self.playbackProgressBar.setValue(0.0, animated: false)
                self.playbackProgressCollapsedBar.progress = 0.0
                return
            }
            let currentPlaybackTime = self.audioQueuePlayer.currentPlaybackTime
            let totalPlaybackTime = Float(self.audioQueuePlayer.nowPlayingItem!.playbackDuration)
            let remainingPlaybackTime = totalPlaybackTime - currentPlaybackTime
            
            self.updatePlaybackProgressBarTimeLabels(currentPlaybackTime:currentPlaybackTime, remainingPlaybackTime:remainingPlaybackTime)
            let progress = currentPlaybackTime
            self.playbackProgressBar.setValue(progress, animated: true)
            self.playbackProgressCollapsedBar.setProgress(Float(progress/totalPlaybackTime), animated: true)
        })
    }
    
    func updatePlaybackProgressBarTimeLabels(currentPlaybackTime currentPlaybackTime:Float, remainingPlaybackTime:Float) {
        totalPlaybackTimeLabel.text = "-" + MediaItemUtils.getTimeRepresentation(remainingPlaybackTime)
        currentPlaybackTimeLabel.text = MediaItemUtils.getTimeRepresentation(currentPlaybackTime)
    }
    
    func updatePlaybackStatus(sender:AnyObject?) {
        if(audioQueuePlayer.musicIsPlaying) {
            playPauseButton.isPlayButton = false
            playPauseCollapsedButton.isPlayButton = false
        } else {
            playPauseButton.isPlayButton = true
            playPauseCollapsedButton.isPlayButton = true
        }
    }
    
    //MARK: - FUNCTIONS: - KVOFunction
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        switch(keyPath!) {
        case "frame","center":
            updateAlphaLevels()
        default:
            Logger.debug("non observed property has changed")
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
        
        if alphaLevel > 0 && albumArtwork.hidden {
            albumArtwork.hidden = false
        }
        
        self.albumArtwork.alpha = alphaLevel
        self.nowPlayingCollapsedBar.alpha = (1.0 - alphaLevel)
    }


    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let application = UIApplication.sharedApplication()
        notificationCenter.addObserver(self, selector: "reloadData:",
            name: AudioQueuePlayerUpdate.NowPlayingItemChanged.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadData:",
            name: AudioQueuePlayerUpdate.PlaybackStateUpdate.rawValue, object: audioQueuePlayer)
        
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

