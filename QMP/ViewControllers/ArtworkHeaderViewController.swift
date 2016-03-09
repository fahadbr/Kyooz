//
//  ArtworkHeaderViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/17/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class ArtworkHeaderViewController : HeaderViewController {
    
    override var defaultHeight:CGFloat {
        return 375
    }
    
    override var minimumHeight:CGFloat {
        return 110
    }
    
    private var expandedFraction:CGFloat {
        return (view.frame.height - minimumHeight)/(defaultHeight - minimumHeight)
    }
    
    private var observationKey:String {
        return "bounds"
    }
    
    //MARK: - IBOutlets
    
    @IBOutlet var headerTitleLabel: UILabel!
    @IBOutlet var detailsLabel1: UILabel!
    @IBOutlet var detailsLabel2: UILabel!
    @IBOutlet var detailsLabel3: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var imageViewContainer: UIView!
    
    //MARK: - properties
	
	private var blurViewController:BlurViewController!
    private var observingViewBounds = false
    private var kvoContext:UInt8 = 123
	
	private let clearGradiantDefaultLocations:(start:CGFloat, end:CGFloat) = (0.25, 0.75)
    private let gradiantLayer:CAGradientLayer = {
        let gradiant = CAGradientLayer()
        gradiant.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradiant.endPoint = CGPoint(x: 0.5, y: 0)
        gradiant.colors = [ThemeHelper.defaultTableCellColor.CGColor, UIColor.clearColor().CGColor, UIColor.clearColor().CGColor, ThemeHelper.defaultTableCellColor.CGColor]
		
        gradiant.locations = [0.0, 0.25, 0.75, 1.0]
        return gradiant
    }()
    
    deinit {
        if observingViewBounds {
            view.removeObserver(self, forKeyPath: observationKey)
        }
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //MARK: - vc life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        blurViewController = BlurViewController()
		addChildViewController(blurViewController)
		blurViewController.didMoveToParentViewController(self)
		
		let blurView = blurViewController.view
        imageViewContainer.insertSubview(blurView, aboveSubview: imageView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.topAnchor.constraintEqualToAnchor(imageView.topAnchor).active = true
        blurView.bottomAnchor.constraintEqualToAnchor(imageView.bottomAnchor).active = true
        blurView.rightAnchor.constraintEqualToAnchor(imageView.rightAnchor).active = true
        blurView.leftAnchor.constraintEqualToAnchor(imageView.leftAnchor).active = true
		blurViewController.blurRadius = 0
		
        view.backgroundColor = ThemeHelper.defaultTableCellColor
        view.addObserver(self, forKeyPath: observationKey, options: .New, context: &kvoContext)
        observingViewBounds = true //this is to ensure we dont remove the observer before adding one

        view.layer.shadowOffset = CGSize(width: 0, height: 3)

    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        super.didMoveToParentViewController(parent)
        guard let vc = parent as? AudioEntityHeaderViewController else { return }
        configureViewWithCollection(vc.sourceData.entities)
    }
	
    //MARK: - class functions
    
    func configureViewWithCollection(entities:[AudioEntity]) {
        guard let track = entities.first?.representativeTrack else {
            Logger.debug("couldnt get representative item for album collection")
            return
        }
        
        gradiantLayer.frame = view.bounds
        view.layer.insertSublayer(gradiantLayer, above: imageViewContainer.layer)
        
        headerTitleLabel.text = track.albumTitle?.uppercaseString
        
        detailsLabel1.text = track.albumArtist ?? track.artist
        
        var details = [String]()
        if let mediaItem = track as? MPMediaItem, let releaseDate = MediaItemUtils.getReleaseDateString(mediaItem) {
            details.append(releaseDate)
        }
        if let genre = track.genre {
            details.append(genre)
        }
        details.append("\(entities.count) Tracks")
        
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
            guard let tracks = entities as? [AudioTrack] else {
                detailsLabel2.hidden = true
                return
            }
            
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
            
            blurViewController.blurRadius = timeOffsetForBlur(expandedFraction)
            
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            imageView.layer.transform = CATransform3DMakeTranslation(0, (1 - expandedFraction) * 0.2 * imageView.frame.height * -1, 0)
            gradiantLayer.frame = view.bounds
            
            if expandedFraction < 0.25 {
                let scaledFraction = Float(expandedFraction) * 4
                view.layer.shadowOpacity =  1 - scaledFraction
                gradiantLayer.opacity = scaledFraction
                
            } else {
                view.layer.shadowOpacity = 0
                gradiantLayer.opacity = 1
            }
            CATransaction.commit()
            
        }
    }
    
    private func timeOffsetForBlur(expandedFraction:CGFloat) -> Double {
        return expandedFraction <= 0.75 ? Double(1.0 - (expandedFraction * 4.0/3.0)) : 0
    }
    
}
