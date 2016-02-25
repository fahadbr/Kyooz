//
//  CollectionDetailsHeaderViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/17/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer
import GLKit

let observationKey = "bounds"

final class CollectionDetailsHeaderViewController : UIViewController, HeaderViewControllerProtocol, GLKViewDelegate {
    
    static let blurContext:CIContext = {
        let options:[String:AnyObject] = [kCIContextWorkingColorSpace:NSNull()]
        return CIContext(EAGLContext: eaglContext, options: options)
    }()
	
	static let eaglContext:EAGLContext = {
		return EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
	}()
    
    static let backgroundQueue:dispatch_queue_t = {
        let attribute = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, -1)
        let queue = dispatch_queue_create("kyooz.BlurBackgroundQueue", attribute)
        return queue
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
	
	var glkView:GLKView!
    
    var originalImage:UIImage!
	var lowQualityImage:UIImage!
	var originalCIImage:CIImage!
    var blurFilter:CIFilter!
    var blurContext:CIContext { return CollectionDetailsHeaderViewController.blurContext }
	var eaglContext:EAGLContext { return CollectionDetailsHeaderViewController.eaglContext }
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
        tint.backgroundColor = ThemeHelper.defaultTableCellColor.CGColor
        tint.opacity = 0
        return tint
    }()
	
    //MARK: - vc life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addObserver(self, forKeyPath: observationKey, options: .New, context: &kvoContext)
        view.layer.shadowOffset = CGSize(width: 0, height: 3)
		
		glkView = GLKView(frame: imageView.frame, context: eaglContext)

		imageViewContainer.insertSubview(glkView, aboveSubview: imageView)
		glkView.translatesAutoresizingMaskIntoConstraints = false
		glkView.topAnchor.constraintEqualToAnchor(imageView.topAnchor).active = true
		glkView.bottomAnchor.constraintEqualToAnchor(imageView.bottomAnchor).active = true
		glkView.rightAnchor.constraintEqualToAnchor(imageView.rightAnchor).active = true
		glkView.leftAnchor.constraintEqualToAnchor(imageView.leftAnchor).active = true
//		glkView.hidden = true
        glkView.delegate = self
        glkView.enableSetNeedsDisplay = false
        EAGLContext.setCurrentContext(eaglContext)
        
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
				
				let lqScale:CGFloat = 2
				
                if let image = albumArt.imageWithSize(albumImageView.frame.size), lqImage = albumArt.imageWithSize(CGSize(width: albumImageView.frame.width/lqScale, height: albumImageView.frame.height/lqScale)) {
					self?.lowQualityImage = lqImage
                    if let filter = CIFilter(name: "CIGaussianBlur") {
						if let ciImage = CIImage(image: image) {
							self?.originalCIImage = ciImage
							filter.setValue(ciImage, forKey: kCIInputImageKey)
							filter.setValue(NSNumber(integer: 0), forKey: kCIInputRadiusKey)
							self?.blurFilter = filter
						}
                    }
                    
                    self?.originalImage = image
                    albumImageView.image = image
                    
                    dispatch_async(CollectionDetailsHeaderViewController.backgroundQueue) {
                        self?.updateBlur(1)
                    }
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

            dispatch_async(CollectionDetailsHeaderViewController.backgroundQueue) {
                self.updateBlur(expandedFraction)
            }


            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            imageView.layer.transform = CATransform3DMakeTranslation(0, (1 - expandedFraction) * 0.2 * imageView.frame.height * -1, 0)
            glkView.layer.transform = CATransform3DMakeTranslation(0, (1 - expandedFraction) * 0.2 * imageView.frame.height * -1, 0)
            
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
    
//    private func updateBlur(expandedFraction:CGFloat) {
//        var imageToSet:UIImage?
//        if expandedFraction <= 0.5 {
//            if self.blurFilter?.setValue(NSNumber(float: (1 - Float(expandedFraction * 2)) * 20), forKey: kCIInputRadiusKey) != nil {
//                if let blurImage = self.blurFilter.outputImage {
//                    let cgImage = self.blurContext.createCGImage(blurImage, fromRect: self.originalCIImage.extent)
//                    imageToSet = UIImage(CGImage: cgImage)
//                }
//            }
////            imageView.image = lowQualityImage.uie_boxblurImageWithBlur(1 - (expandedFraction * 2))
//        }
//        
//        KyoozUtils.doInMainQueue() {
//            self.imageView.image = imageToSet ?? self.originalImage
//        }
//    }
    
    private func updateBlur(expandedFraction:CGFloat) {
        glkView?.display()
    }
    
    func glkView(view: GLKView, drawInRect rect: CGRect) {
        let expandedFraction = (self.view.frame.height - minimumHeight)/(height - minimumHeight)
        let blurRadius:Float = expandedFraction > 0.5 ? 0 : (1 - Float(expandedFraction * 2)) * 20
        if blurFilter?.setValue(NSNumber(float: blurRadius), forKey: kCIInputRadiusKey) != nil {
            if let blurImage = blurFilter.outputImage {
                glClearColor(0.5, 0.5, 0.5, 1.0)
                glClear(UInt32(GL_COLOR_BUFFER_BIT))
                glEnable(UInt32(GL_BLEND))
                glBlendFunc(UInt32(GL_ONE), UInt32(GL_ONE_MINUS_SRC_ALPHA))
                
               
                blurContext.drawImage(blurImage, inRect: CGRect(origin: CGPoint.zero, size: CGSize(width: glkView.drawableWidth, height: glkView.drawableHeight)), fromRect: originalCIImage.extent)
            }
        }
    }
    

}
