//
//  CollectionDetailsHeaderViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/17/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

let observationKey = "bounds"

final class CollectionDetailsHeaderViewController : UIViewController, HeaderViewControllerProtocol {
    
    static let blurContext:CIContext = {
        let eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
        let options:[String:AnyObject] = [kCIContextWorkingColorSpace:NSNull()]
        return CIContext(EAGLContext: eaglContext, options: options)
    }()
    
    
    var height:CGFloat {
//        return (parentViewController?.view?.frame.height ?? UIScreen.mainScreen().bounds.height)/2
        return 375
    }
    
    var minimumHeight:CGFloat {
        return 110
    }
    
    //MARK: - IBOutlets
    
    @IBOutlet var shuffleButton: ShuffleButtonView!
    @IBOutlet var selectModeButton: ListButtonView!
    @IBOutlet var headerTitleLabel: UILabel!
    @IBOutlet var detailsLabel1: UILabel!
    @IBOutlet var detailsLabel2: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var imageViewContainer: UIView!
    
    //MARK: - properties
    
    var blurView:UIVisualEffectView!
    
    var originalImage:UIImage!
    var blurFilter:CIFilter!
    var blurContext:CIContext { return CollectionDetailsHeaderViewController.blurContext }
    
    var observingHeaderView = false
    var kvoContext:UInt8 = 123
    
	let gradiant:CAGradientLayer = {
		let gradiant = CAGradientLayer()
		gradiant.startPoint = CGPoint(x: 0.5, y: 1.0)
		gradiant.endPoint = CGPoint(x: 0.5, y: 0)
		gradiant.colors = [ThemeHelper.defaultTableCellColor.CGColor, UIColor.clearColor().CGColor, UIColor.clearColor().CGColor, ThemeHelper.defaultTableCellColor.CGColor]
        gradiant.locations = [0.0, 0.25, 0.75, 1.0]
		return gradiant
	}()
    
    let tintLayer:CALayer = {
        let tint = CALayer()
        tint.backgroundColor = UIColor.blackColor().CGColor
        tint.opacity = 0
        return tint
    }()
	
    //MARK: - vc life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addObserver(self, forKeyPath: observationKey, options: .New, context: &kvoContext)
        view.layer.shadowOffset = CGSize(width: 0, height: 3)
        
//        blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
//        blurView.frame = imageView.bounds
//        imageView.addSubview(blurView)
//        blurView.alpha = 0
        
        view.backgroundColor = ThemeHelper.defaultTableCellColor
        observingHeaderView = true
    }
    
    deinit {
        if observingHeaderView {
            view.removeObserver(self, forKeyPath: observationKey)
        }
    }
    
    //MARK: - class functions
    
    func configureViewWithCollection(tracks:[AudioTrack]) {
        guard let track = tracks.first else {
            Logger.debug("couldnt get representative item for album collection")
            return
        }
		
		gradiant.frame = view.bounds
        tintLayer.frame = view.bounds
        view.layer.insertSublayer(tintLayer, above: imageViewContainer.layer)
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
        
        detailsLabel2.text = details.joinWithSeparator(" • ")
        detailsLabel2.textColor = UIColor.lightGrayColor()
        
        if let albumArt = track.artwork {
            KyoozUtils.doInMainQueueAsync() { [weak self, albumImageView = self.imageView] in
                if let image = albumArt.imageWithSize(albumImageView.frame.size) {
                    if let filter = CIFilter(name: "CIBoxBlur"), let ciImage = CIImage(image: image) {
                        filter.setValue(ciImage, forKey: kCIInputImageKey)
                        filter.setValue(NSNumber(integer: 0), forKey: kCIInputRadiusKey)
                        self?.blurFilter = filter
                    }
                    
                    self?.originalImage = image
                    albumImageView.image = image
                }
            }
        } else {
            view.backgroundColor = ThemeHelper.darkAccentColor
        }
        
        headerTitleLabel.layer.shouldRasterize = true
        headerTitleLabel.layer.rasterizationScale = UIScreen.mainScreen().scale
        detailsLabel2.layer.shouldRasterize = true
        detailsLabel2.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        KyoozUtils.doInMainQueueAsync() { [weak self] in
            
            var duration:NSTimeInterval = 0
            for item in tracks {
                duration += item.playbackDuration
            }
            if let albumDurationString = MediaItemUtils.getLongTimeRepresentation(duration) {
                self?.detailsLabel2.text = "\(albumDurationString) • \(self?.detailsLabel2.text ?? "")"
            } else {
                self?.detailsLabel2.hidden = true
            }
        }

        
    }
    
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath != nil && keyPath! == observationKey {
            let expandedFraction = (view.frame.height - minimumHeight)/(height - minimumHeight)
 
            detailsLabel1.alpha = expandedFraction
//            blurView.alpha = 1 - fraction


//            if blurFilter?.setValue(NSNumber(float: (1 - Float(expandedFraction)) * 20), forKey: kCIInputRadiusKey) != nil {
//                if let blurImage = blurFilter.outputImage {
//                    imageView.image = UIImage(CGImage: blurContext.createCGImage(blurImage, fromRect: blurImage.extent))
//                } else {
//                    imageView.image = originalImage
//                }
//            }

            
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            gradiant.frame = view.bounds
            tintLayer.frame = view.bounds
            tintLayer.opacity = (1 - Float(expandedFraction)) * 0.7
            
            if expandedFraction < 0.25 {
                let scaledFraction = Float(expandedFraction) * 4
                let inverseScaledFraction = 1 - scaledFraction
                view.layer.shadowOpacity =  inverseScaledFraction
                gradiant.opacity = scaledFraction
                

            } else {
                view.layer.shadowOpacity = 0
                gradiant.opacity = 1
            }
            CATransaction.commit()
            
        }
    }
    

}
