//
//  WrapperViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/2/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer


//TODO: Rename this class
//view controller primarily used for wrapping a view in a view controller object
//to be used in a paging controller. the internal views are ones that need to be refreshed upon audio queue player
//changes or notifications
class WrapperViewController : UIViewController {
	
	private (set) var representingIndex:Int
    var completionBlock:(()->())?
	let isPresentedVC:Bool
	
	
    private let wrappedView:UIView
	private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
	
	init(wrappedView:UIView, isPresentedVC:Bool, representingIndex:Int) {
        self.wrappedView = wrappedView
        self.isPresentedVC = isPresentedVC
		self.representingIndex = representingIndex
        super.init(nibName:nil, bundle:nil)
		
		if isPresentedVC {
			NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.refreshIndexAndViews),
				name: AudioQueuePlayerUpdate.NowPlayingItemChanged.rawValue, object: audioQueuePlayer)
			NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.refreshIndexAndViews),
			                                                 name: AudioQueuePlayerUpdate.QueueUpdate.rawValue, object: audioQueuePlayer)
			NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.refreshIndexAndViews),
			                                                 name: AudioQueuePlayerUpdate.SystematicQueueUpdate.rawValue, object: audioQueuePlayer)
			NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.refreshIndexAndViews),
			    name: UIApplicationDidBecomeActiveNotification, object: UIApplication.sharedApplication())
		}
    }
	
	deinit {
		if isPresentedVC {
			NSNotificationCenter.defaultCenter().removeObserver(self)
		}
	}
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view.addSubview(wrappedView)
    }
	
	func refreshIndexAndViews() {
		guard UIApplication.sharedApplication().applicationState == UIApplicationState.Active else { return }
		
		representingIndex = audioQueuePlayer.indexOfNowPlayingItem
		refreshViews(audioQueuePlayer.nowPlayingItem)
	}
	
	private func refreshViews(track:AudioTrack?) {
		//empty imp
	}
	
}

final class ImageWrapperViewController : WrapperViewController {
	
	let imageView:UIImageView
	
	private let frameInset:CGFloat = 0
	private let imageSize:CGSize
	private var imageID:UInt64
	
	init(track:AudioTrack?, isPresentedVC:Bool, representingIndex:Int, size:CGSize) {
		self.imageSize = size
		let albumArtImage = ImageWrapperViewController.albumArtForTrack(track, size: size)
		imageID = track?.albumId ?? 0
		imageView = UIImageView(image: albumArtImage)
		imageView.contentMode = .ScaleAspectFit
		super.init(wrappedView: imageView, isPresentedVC: isPresentedVC, representingIndex: representingIndex)
        
        if isPresentedVC {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.clearImageIdAndRefreshViews),
                                                             name: MPMediaLibraryDidChangeNotification, object: MPMediaLibrary.defaultMediaLibrary())
        }
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		wrappedView.frame = CGRectInset(view.bounds, frameInset, frameInset)
	}
    
    func clearImageIdAndRefreshViews() {
        imageID = 0
        refreshIndexAndViews()
    }
	
	private static func albumArtForTrack(track:AudioTrack?, size:CGSize) -> UIImage {
        return track?.artworkImage(forSize:size) ?? {
            let smallerSide = min(size.height, size.width)
            return ImageUtils.resizeImage(ImageContainer.defaultAlbumArtworkImage, toSize: CGSize(width: smallerSide, height: smallerSide))
        }()
	}
	
	private override func refreshViews(track: AudioTrack?) {
		let newImageID = track?.albumId ?? 0
		guard newImageID != imageID else { return }
		
		let albumArtImage = ImageWrapperViewController.albumArtForTrack(track, size: imageSize)
		imageID = newImageID
		UIView.transitionWithView(imageView, duration: 0.5, options: .TransitionCrossDissolve, animations: {
				self.imageView.image = albumArtImage
			}, completion: nil)
	}
}

final class LabelStackWrapperViewController : WrapperViewController {
	
	private let trackTitleMarqueeLabel:MarqueeLabel
	private let trackDetailsMarqueeLabel:MarqueeLabel
    private let useSmallFont:Bool
	
    init(track:AudioTrack?, isPresentedVC:Bool, representingIndex:Int, useSmallFont:Bool = true) {
		
		func configureLabel(label:UILabel, font:UIFont?) {
			label.textColor = ThemeHelper.defaultFontColor
			label.textAlignment = .Center
			label.font = font
		}
		self.useSmallFont = useSmallFont
        let sizeToUse = useSmallFont ? ThemeHelper.smallFontSize : ThemeHelper.defaultFontSize
		trackTitleMarqueeLabel = MarqueeLabel(labelConfigurationBlock: { (label) in
			configureLabel(label, font: UIFont(name: ThemeHelper.defaultFontNameBold, size: sizeToUse + 1))
		})
		trackDetailsMarqueeLabel = MarqueeLabel(labelConfigurationBlock: { (label) in
			configureLabel(label, font: UIFont(name: ThemeHelper.defaultFontName, size: sizeToUse - 1))
		})
		
		let labelStrings = LabelStackWrapperViewController.getLabelStringsFromTrack(track)
		
		trackTitleMarqueeLabel.text = labelStrings.titleText
		trackDetailsMarqueeLabel.text = labelStrings.detailsText
		
		let height = trackTitleMarqueeLabel.intrinsicContentSize().height + trackDetailsMarqueeLabel.intrinsicContentSize().height
		
		let labelStackView = UIStackView(arrangedSubviews: [trackTitleMarqueeLabel, trackDetailsMarqueeLabel])
		labelStackView.axis = .Vertical
		labelStackView.distribution = .FillProportionally
		
		labelStackView.frame = CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.width, height: height)
		
		super.init(wrappedView: labelStackView, isPresentedVC:isPresentedVC, representingIndex:representingIndex)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
        if useSmallFont {
            wrappedView.frame = CGRectInset(view.bounds, 0, 5)
        } else {
            wrappedView.frame = view.bounds
        }
	}
	
	private static func getLabelStringsFromTrack(track:AudioTrack?) -> (titleText:String, detailsText:String) {
		let titleText = track?.trackTitle ?? "Nothing"
		let detailsText = "\(track?.albumArtist ?? "To")  —  \(track?.albumTitle ?? "Play")"
		return (titleText, detailsText)
	}
	
	private override func refreshViews(track: AudioTrack?) {
		let labelStrings = LabelStackWrapperViewController.getLabelStringsFromTrack(track)
		func updateLabel(label:MarqueeLabel, text:String) {
			if label.text == nil || label.text! != text {
				label.setText(text, animated: true)
			}
		}
		
		updateLabel(trackTitleMarqueeLabel, text: labelStrings.titleText)
		KyoozUtils.doInMainQueueAfterDelay(0.2) {
			updateLabel(self.trackDetailsMarqueeLabel, text: labelStrings.detailsText)
		}
	}
	
}
