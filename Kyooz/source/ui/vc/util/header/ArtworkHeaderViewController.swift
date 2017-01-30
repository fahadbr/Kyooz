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
	
	private typealias This = ArtworkHeaderViewController
    
    override var defaultHeight:CGFloat {
        return UIScreen.main.bounds.width
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
		$0.font = ThemeHelper.defaultFont(forStyle: .bold)
		$0.textAlignment = .center
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
        gradiant.colors = [ThemeHelper.defaultTableCellColor.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor, ThemeHelper.defaultTableCellColor.cgColor]
		
		gradiant.locations = [0.0,
		                      NSNumber(value: Float(This.clearGradiantDefaultLocations.start)),
		                      NSNumber(value: Float(This.clearGradiantDefaultLocations.end)),
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
        ConstraintUtils.applyConstraintsToView(withAnchors: [.left, .right, .top], subView: imageView, parentView: imageViewContainer)
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        
        ConstraintUtils.applyConstraintsToView(withAnchors: [.centerX, .width], subView: headerTitleLabel, parentView: view)[.width]!.constant = -100
        headerTitleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 25).isActive = true
        headerTitleLabel.heightAnchor.constraint(equalToConstant: 42).isActive = true
        

		addChildViewController(blurViewController)
		blurViewController.didMove(toParentViewController: self)
        
		
		let blurView = blurViewController.view
        imageViewContainer.insertSubview(blurView!, aboveSubview: imageView)
        blurView?.translatesAutoresizingMaskIntoConstraints = false
        blurView?.topAnchor.constraint(equalTo: imageView.topAnchor).isActive = true
        blurView?.bottomAnchor.constraint(equalTo: imageView.bottomAnchor).isActive = true
        blurView?.rightAnchor.constraint(equalTo: imageView.rightAnchor).isActive = true
        blurView?.leftAnchor.constraint(equalTo: imageView.leftAnchor).isActive = true
		blurViewController.blurRadius = 0
		
        view.backgroundColor = ThemeHelper.defaultTableCellColor
        view.addObserver(self, forKeyPath: observationKey, options: .new, context: &kvoContext)
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
    
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        guard let vc = parent as? AudioEntityLibraryViewController else { return }
        KyoozUtils.doInMainQueueAsync() {
            self.configureViewWithCollection(vc.sourceData)
        }
    }
	
    //MARK: - class functions
    
    func configureViewWithCollection(_ sourceData:AudioEntitySourceData) {
        guard let track = sourceData.entities.first?.representativeTrack else {
            Logger.debug("couldnt get representative item for album collection")
            return
        }
		
		let presentedEntity:AudioEntity = sourceData.parentCollection ?? track
        gradiantLayer.frame = view.bounds
        view.layer.insertSublayer(gradiantLayer, above: imageViewContainer.layer)
        
        headerTitleLabel.text = presentedEntity.titleForGrouping(sourceData.parentGroup ?? LibraryGrouping.Albums)?.uppercased()
        headerTitleLabel.layer.shouldRasterize = true
        headerTitleLabel.layer.rasterizationScale = UIScreen.main.scale
        
        //fade in the artwork
        presentedEntity.artworkImage(forSize: imageView.frame.size) { [imageView = self.imageView, fadeInAnimation = type(of: self).fadeInAnimation](image) in
            imageView.image = image
            imageView.layer.add(fadeInAnimation, forKey: nil)
        }

    }
    
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
		
        guard keyPath != nil && keyPath! == observationKey else { return }
		
		func adjustGradientLocation(expandedFraction:CGFloat, invertedFraction:CGFloat) {
			let locations = type(of: self).clearGradiantDefaultLocations
			
			//ranges from 25 -> 0 as view collapses
			let clearGradiantStart = NSNumber(value: Float(min(locations.start * expandedFraction, locations.start)))
			
			//ranges from 75 -> 100 as view collapses
			let clearGradiantEnd = NSNumber(value: Float(max((0.25 * invertedFraction) + locations.end, locations.end)))
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
