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
    
    private static let clearGradiantDefaultLocations:(start:CGFloat, end:CGFloat) = (0.25, 0.75)
    private static let fadeInAnimation = KyoozUtils.fadeInAnimationWithDuration(0.4)
    
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
	@IBOutlet var labelStackView: UIStackView!
    @IBOutlet var detailsLabel1: UILabel!
    @IBOutlet var detailsLabel2: UILabel!
    @IBOutlet var detailsLabel3: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var imageViewContainer: UIView!
    
    //MARK: - properties
	
	private var blurViewController:BlurViewController!
    private var observingViewBounds = false
    private var kvoContext:UInt8 = 123
	

    private let gradiantLayer:CAGradientLayer = {
        let gradiant = CAGradientLayer()
        gradiant.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradiant.endPoint = CGPoint(x: 0.5, y: 0)
        gradiant.colors = [ThemeHelper.defaultTableCellColor.CGColor, UIColor.clearColor().CGColor, UIColor.clearColor().CGColor, ThemeHelper.defaultTableCellColor.CGColor]
		
        gradiant.locations = [0.0,
            ArtworkHeaderViewController.clearGradiantDefaultLocations.start,
            ArtworkHeaderViewController.clearGradiantDefaultLocations.end,
            1.0]
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
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		labelStackView.layer.transform = CATransform3DMakeTranslation(0, expandedFraction * 8, 0)
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
                    imageView.layer.addAnimation(ArtworkHeaderViewController.fadeInAnimation, forKey: nil)
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
        guard keyPath != nil && keyPath! == observationKey else { return }
		
		func adjustGradientLocation(expandedFraction expandedFraction:CGFloat, invertedFraction:CGFloat) {
			let clearGradiantStart = min(self.dynamicType.clearGradiantDefaultLocations.start * expandedFraction, self.dynamicType.clearGradiantDefaultLocations.start) //ranges from 25 -> 0 as view collapses
			let clearGradiantEnd = max((0.25 * invertedFraction) + self.dynamicType.clearGradiantDefaultLocations.end, self.dynamicType.clearGradiantDefaultLocations.end) //ranges from 75 -> 100 as view collapses
			gradiantLayer.locations = [0.0, clearGradiantStart, clearGradiantEnd, 1.0]
		}
		
        CATransaction.begin()
        CATransaction.setDisableActions(true)
		defer {
			CATransaction.commit()
		}
		
        let expandedFraction = self.expandedFraction
        let invertedFraction = 1 - expandedFraction
		
		gradiantLayer.frame = view.bounds
		
		if expandedFraction >= 1 {
			let overexpandedFraction = (expandedFraction - 1) * 5.0/2.0
			let invertedOverexpandedFraction = 1 - overexpandedFraction
			labelStackView.alpha = invertedOverexpandedFraction
			shuffleButton.alpha = invertedOverexpandedFraction * ThemeHelper.defaultButtonTextAlpha
			selectModeButton.alpha = invertedOverexpandedFraction * ThemeHelper.defaultButtonTextAlpha
			headerTitleLabel.alpha = invertedOverexpandedFraction
			gradiantLayer.opacity = Float(invertedOverexpandedFraction)
			adjustGradientLocation(expandedFraction: invertedOverexpandedFraction, invertedFraction: overexpandedFraction)
			imageView.layer.transform = CATransform3DMakeTranslation(0, overexpandedFraction * 0.2 * imageView.frame.height, 0)
			return
		}
        
        detailsLabel1.alpha = expandedFraction
        
        blurViewController.blurRadius = expandedFraction <= 0.75 ? Double(1.0 - (expandedFraction * 4.0/3.0)) : 0
        
		labelStackView.layer.transform = CATransform3DMakeTranslation(0, expandedFraction * 8, 0)
        imageView.layer.transform = CATransform3DMakeTranslation(0, invertedFraction * 0.2 * imageView.frame.height * -1, 0)

		adjustGradientLocation(expandedFraction: expandedFraction, invertedFraction: invertedFraction)
        
        if expandedFraction < 0.25 {
            let scaledFraction = Float(expandedFraction) * 4
            view.layer.shadowOpacity =  1 - scaledFraction
            gradiantLayer.opacity = scaledFraction

        } else {
            view.layer.shadowOpacity = 0
            gradiantLayer.opacity = 1
        }
    }
    
}
