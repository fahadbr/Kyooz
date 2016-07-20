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
        return UIScreen.mainScreen().bounds.width
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
    
	private lazy var headerTitleLabel: UILabel = {
		$0.textColor = ThemeHelper.defaultFontColor
		$0.font = ThemeHelper.defaultFont(forStyle: .Bold)
		$0.textAlignment = .Center
		$0.numberOfLines = 3
		return $0
	}(UILabel())

    private lazy var imageView: UIImageView = UIImageView()
    private lazy var imageViewContainer: UIView = UIView()
    
    //MARK: - properties
	
    private lazy var blurViewController:BlurViewController = BlurViewController()

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
    }
    
    //MARK: - vc life cycle
    override func viewDidLoad() {
        imageView.clipsToBounds = true
        imageViewContainer.clipsToBounds = true
        ConstraintUtils.applyStandardConstraintsToView(subView: imageViewContainer, parentView: view)
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Left, .Right, .Top], subView: imageView, parentView: imageViewContainer)
        imageView.heightAnchor.constraintEqualToAnchor(imageView.widthAnchor).active = true
        
        ConstraintUtils.applyConstraintsToView(withAnchors: [.CenterX, .Width], subView: headerTitleLabel, parentView: view)[.Width]!.constant = -100
        headerTitleLabel.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: 25).active = true
        headerTitleLabel.heightAnchor.constraintEqualToConstant(42).active = true
        

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
        
        //calling viewDidLoad at the end so that the views added by the parent class
        //can be placed on top of the image view container
        super.viewDidLoad()
    }
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		(centerViewController as? HeaderLabelStackController)?.labelStackView.layer.transform = CATransform3DMakeTranslation(0, expandedFraction * 8, 0)
	}
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        super.didMoveToParentViewController(parent)
        guard let vc = parent as? AudioEntityLibraryViewController else { return }
        KyoozUtils.doInMainQueueAsync() {
            self.configureViewWithCollection(vc.sourceData)
        }
    }
	
    //MARK: - class functions
    
    func configureViewWithCollection(sourceData:AudioEntitySourceData) {
        guard let track = sourceData.entities.first?.representativeTrack else {
            Logger.debug("couldnt get representative item for album collection")
            return
        }
		
		let presentedEntity:AudioEntity = sourceData.parentCollection ?? track
        gradiantLayer.frame = view.bounds
        view.layer.insertSublayer(gradiantLayer, above: imageViewContainer.layer)
        
        headerTitleLabel.text = presentedEntity.titleForGrouping(sourceData.parentGroup ?? LibraryGrouping.Albums)?.uppercaseString
        headerTitleLabel.layer.shouldRasterize = true
        headerTitleLabel.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        //fade in the artwork
        presentedEntity.artworkImage(forSize: imageView.frame.size) { [imageView = self.imageView, fadeInAnimation = self.dynamicType.fadeInAnimation](image) in
            imageView.image = image
            imageView.layer.addAnimation(fadeInAnimation, forKey: nil)
        }

    }
    
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard keyPath != nil && keyPath! == observationKey else { return }
		
		func adjustGradientLocation(expandedFraction expandedFraction:CGFloat, invertedFraction:CGFloat) {
			let locations = self.dynamicType.clearGradiantDefaultLocations
			
			//ranges from 25 -> 0 as view collapses
			let clearGradiantStart = min(locations.start * expandedFraction, locations.start)
			
			//ranges from 75 -> 100 as view collapses
			let clearGradiantEnd = max((0.25 * invertedFraction) + locations.end, locations.end)
			gradiantLayer.locations = [0.0, clearGradiantStart, clearGradiantEnd, 1.0]
		}
		
        CATransaction.begin()
        CATransaction.setDisableActions(true)
		defer {
			CATransaction.commit()
		}
        
        let labelStackView = (centerViewController as? HeaderLabelStackController)?.labelStackView
        let detailsLabel1:UIView? = labelStackView?.arrangedSubviews.count == 3 ? labelStackView?.arrangedSubviews.first : nil
		
        let expandedFraction = self.expandedFraction
        let invertedFraction = 1 - expandedFraction
		
		gradiantLayer.frame = view.bounds
		
        if expandedFraction >= 1 {
            var overexpandedFraction = (expandedFraction - 1) * 5.0/2.0
            var invertedOverexpandedFraction = 1 - overexpandedFraction
            
            imageView.layer.transform = CATransform3DMakeTranslation(0, overexpandedFraction * 0.2 * imageView.frame.height, 0)
            if expandedFraction >= 1.2 {
                overexpandedFraction = (expandedFraction - 1.2) * 5.0/2.0
                invertedOverexpandedFraction = 1 - overexpandedFraction
                centerViewController.view.alpha = invertedOverexpandedFraction
                leftButton.alpha = invertedOverexpandedFraction * ThemeHelper.defaultButtonTextAlpha
                selectButton.alpha = invertedOverexpandedFraction * ThemeHelper.defaultButtonTextAlpha
                headerTitleLabel.alpha = invertedOverexpandedFraction
                gradiantLayer.opacity = Float(invertedOverexpandedFraction)
                adjustGradientLocation(expandedFraction: invertedOverexpandedFraction, invertedFraction: overexpandedFraction)
            }
            return
        }
        
        detailsLabel1?.alpha = expandedFraction
        
        blurViewController.blurRadius = expandedFraction <= 0.75 ? Double(1.0 - (expandedFraction * 4.0/3.0)) : 0
        
		labelStackView?.layer.transform = CATransform3DMakeTranslation(0, expandedFraction * 8, 0)
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
