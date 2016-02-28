//
//  CollectionDetailsHeaderViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/17/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class CollectionDetailsHeaderViewController : UIViewController, HeaderViewControllerProtocol {
    
    var height:CGFloat {
        //        return (parentViewController?.view?.frame.height ?? UIScreen.mainScreen().bounds.height)/2
        return 375
    }
    
    var minimumHeight:CGFloat {
        return 110
    }
    
    private var expandedFraction:CGFloat {
        return (view.frame.height - minimumHeight)/(height - minimumHeight)
    }
    
    private var observationKey:String {
        return "bounds"
    }
    
    //MARK: - IBOutlets
    
    @IBOutlet var shuffleButton: ShuffleButtonView!
    @IBOutlet var selectModeButton: ListButtonView!
    @IBOutlet var headerTitleLabel: UILabel!
    @IBOutlet var detailsLabel1: UILabel!
    @IBOutlet var detailsLabel2: UILabel!
    @IBOutlet var detailsLabel3: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var imageViewContainer: UIView!
    
    //MARK: - properties
    
    private var blurView:UIVisualEffectView!
    private var finalBlurEffect:UIVisualEffect = UIBlurEffect(style: .Dark)
    private var blurSnapshotView:UIView? {
        willSet {
            if let snapshot = newValue {
                imageViewContainer?.addSubview(snapshot)
            } else {
                blurSnapshotView?.removeFromSuperview()
            }
        }
    }
    
    private var observingHeaderView = false
    private var kvoContext:UInt8 = 123
    private var viewHasDisappeared = false
    
    private let gradiant:CAGradientLayer = {
        let gradiant = CAGradientLayer()
        gradiant.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradiant.endPoint = CGPoint(x: 0.5, y: 0)
        gradiant.colors = [ThemeHelper.defaultTableCellColor.CGColor, UIColor.clearColor().CGColor, UIColor.clearColor().CGColor, ThemeHelper.defaultTableCellColor.CGColor]
        gradiant.locations = [0.0, 0.25, 0.75, 1.0]
        return gradiant
    }()
    
    //MARK: - vc life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        blurView = UIVisualEffectView()
        imageViewContainer.insertSubview(blurView, aboveSubview: imageView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.topAnchor.constraintEqualToAnchor(imageView.topAnchor).active = true
        blurView.bottomAnchor.constraintEqualToAnchor(imageView.bottomAnchor).active = true
        blurView.rightAnchor.constraintEqualToAnchor(imageView.rightAnchor).active = true
        blurView.leftAnchor.constraintEqualToAnchor(imageView.leftAnchor).active = true
        blurView.layer.speed = 0
        resetBlurAnimation()
        
        view.backgroundColor = ThemeHelper.defaultTableCellColor
        view.addObserver(self, forKeyPath: observationKey, options: .New, context: &kvoContext)
        observingHeaderView = true

        view.layer.shadowOffset = CGSize(width: 0, height: 3)
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "createSnapshotBlur", name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        notificationCenter.addObserver(self, selector: "removeBlurAnimation", name: UIApplicationDidEnterBackgroundNotification, object: UIApplication.sharedApplication())
        notificationCenter.addObserver(self, selector: "resetBlurAnimation", name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
        notificationCenter.addObserver(self, selector: "removeSnapshotBlur", name: UIApplicationDidBecomeActiveNotification, object: UIApplication.sharedApplication())
    }
    
    deinit {
        if observingHeaderView {
            view.removeObserver(self, forKeyPath: observationKey)
        }
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        if viewHasDisappeared {
            resetBlurAnimation()
            removeSnapshotBlur()
            viewHasDisappeared = false
        }
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        createSnapshotBlur()
        removeBlurAnimation()
        viewHasDisappeared = true
        super.viewDidDisappear(animated)
    }
    
    //MARK: - class functions
    
    func configureViewWithCollection(tracks:[AudioTrack]) {
        guard let track = tracks.first else {
            Logger.debug("couldnt get representative item for album collection")
            return
        }
        
        gradiant.frame = view.bounds
        view.layer.insertSublayer(gradiant, above: imageViewContainer.layer)
        
        headerTitleLabel.text = track.albumTitle?.uppercaseString
        
        detailsLabel1.text = track.albumArtist ?? track.artist
        
        var details = [String]()
        if let mediaItem = track as? MPMediaItem, let releaseDate = MediaItemUtils.getReleaseDateString(mediaItem) {
            details.append(releaseDate)
        }
        if let genre = track.genre {
            details.append(genre)
        }
        details.append("\(tracks.count) Tracks")
        
        detailsLabel3.text = details.joinWithSeparator(" • ")
        detailsLabel3.textColor = UIColor.lightGrayColor()
        detailsLabel2.textColor = UIColor.lightGrayColor()
        if let albumArt = track.artwork {
            KyoozUtils.doInMainQueueAsync() { [imageView = self.imageView] in
                if let image = albumArt.imageWithSize(imageView.frame.size) {
                    imageView.image = image
                }
            }
        } else {
            view.backgroundColor = ThemeHelper.darkAccentColor
        }
        
        headerTitleLabel.layer.shouldRasterize = true
        headerTitleLabel.layer.rasterizationScale = UIScreen.mainScreen().scale
        detailsLabel2.layer.shouldRasterize = true
        detailsLabel2.layer.rasterizationScale = UIScreen.mainScreen().scale
        detailsLabel3.layer.shouldRasterize = true
        detailsLabel3.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        KyoozUtils.doInMainQueueAsync() { [detailsLabel2 = self.detailsLabel2] in
            var duration:NSTimeInterval = 0
            for item in tracks {
                duration += item.playbackDuration
            }
            if let albumDurationString = MediaItemUtils.getLongTimeRepresentation(duration) {
                detailsLabel2.text = "\(albumDurationString)"
            } else {
                detailsLabel2.hidden = true
            }
        }
    }
    
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath != nil && keyPath! == observationKey {
            let expandedFraction = self.expandedFraction
            
            detailsLabel1.alpha = expandedFraction
            
            blurView.layer.timeOffset = timeOffsetForBlur(expandedFraction)
            
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            imageView.layer.transform = CATransform3DMakeTranslation(0, (1 - expandedFraction) * 0.2 * imageView.frame.height * -1, 0)
            gradiant.frame = view.bounds
            
            if expandedFraction < 0.25 {
                let scaledFraction = Float(expandedFraction) * 4
                view.layer.shadowOpacity =  1 - scaledFraction
                gradiant.opacity = scaledFraction
                
            } else {
                view.layer.shadowOpacity = 0
                gradiant.opacity = 1
            }
            CATransaction.commit()
            
        }
    }
    
    private func timeOffsetForBlur(expandedFraction:CGFloat) -> Double {
        return expandedFraction <= 0.75 ? Double(1.0 - (expandedFraction * 4.0/3.0)) : 0
    }
    
    func createSnapshotBlur() {
        removeSnapshotBlur()
        blurSnapshotView = imageViewContainer.snapshotViewAfterScreenUpdates(false)
    }
    
    func removeBlurAnimation() {
        blurView.layer.removeAllAnimations()
        blurView.layer.timeOffset = 0
    }
    
    func resetBlurAnimation() {
        removeBlurAnimation()
        blurView.effect = nil
        UIView.animateWithDuration(1) { [blurView = self.blurView, finalBlurEffect = self.finalBlurEffect] in
            blurView.effect = finalBlurEffect
        }
        
        let timeOffset = timeOffsetForBlur(expandedFraction)
        KyoozUtils.doInMainQueueAsync() { [blurView = self.blurView] in
            blurView.layer.timeOffset = timeOffset
        }
    }
    
    func removeSnapshotBlur() {
        blurSnapshotView = nil
    }
    
}