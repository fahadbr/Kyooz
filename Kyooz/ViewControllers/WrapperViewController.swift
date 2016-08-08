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
			NotificationCenter.default.addObserver(self, selector: #selector(self.refreshIndexAndViews),
				name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.nowPlayingItemChanged.rawValue), object: audioQueuePlayer)
			NotificationCenter.default.addObserver(self, selector: #selector(self.refreshIndexAndViews),
			                                                 name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.queueUpdate.rawValue), object: audioQueuePlayer)
			NotificationCenter.default.addObserver(self, selector: #selector(self.refreshIndexAndViews),
			                                                 name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.systematicQueueUpdate.rawValue), object: audioQueuePlayer)
			NotificationCenter.default.addObserver(self, selector: #selector(self.refreshIndexAndViews),
			    name: NSNotification.Name.UIApplicationDidBecomeActive, object: UIApplication.shared)
		}
    }
	
	deinit {
		if isPresentedVC {
			NotificationCenter.default.removeObserver(self)
		}
	}
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view.addSubview(wrappedView)
    }
	
	func refreshIndexAndViews() {
		guard UIApplication.shared.applicationState == UIApplicationState.active else { return }
		
		representingIndex = audioQueuePlayer.indexOfNowPlayingItem
		refreshViews(audioQueuePlayer.nowPlayingItem)
	}
	
	private func refreshViews(_ track:AudioTrack?) {
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
		imageView.contentMode = .scaleAspectFit
		super.init(wrappedView: imageView, isPresentedVC: isPresentedVC, representingIndex: representingIndex)
        
        if isPresentedVC {
            NotificationCenter.default.addObserver(self, selector: #selector(self.clearImageIdAndRefreshViews),
                                                             name: NSNotification.Name.MPMediaLibraryDidChange, object: MPMediaLibrary.default())
        }
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		wrappedView.frame = view.bounds.insetBy(dx: frameInset, dy: frameInset)
	}
    
    func clearImageIdAndRefreshViews() {
        imageID = 0
        refreshIndexAndViews()
    }
	
	private static func albumArtForTrack(_ track:AudioTrack?, size:CGSize) -> UIImage {
        return track?.artworkImage(forSize:size) ?? {
            let smallerSide = min(size.height, size.width)
            return ImageUtils.resizeImage(ImageContainer.defaultAlbumArtworkImage, toSize: CGSize(width: smallerSide, height: smallerSide))
        }()
	}
	
	private override func refreshViews(_ track: AudioTrack?) {
		let newImageID = track?.albumId ?? 0
		guard newImageID != imageID else { return }
		
		let albumArtImage = ImageWrapperViewController.albumArtForTrack(track, size: imageSize)
		imageID = newImageID
		UIView.transition(with: imageView, duration: 0.5, options: .transitionCrossDissolve, animations: {
				self.imageView.image = albumArtImage
			}, completion: nil)
	}
}

final class LabelStackWrapperViewController : WrapperViewController {
	
	private let trackTitleMarqueeLabel:MarqueeLabel
	private let trackDetailsMarqueeLabel:MarqueeLabel
    private let useSmallFont:Bool
	
    init(track:AudioTrack?, isPresentedVC:Bool, representingIndex:Int, useSmallFont:Bool = true) {
		
		func configureLabel(_ label:UILabel, font:UIFont?) {
			label.textColor = ThemeHelper.defaultFontColor
			label.textAlignment = .center
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
		
		let height = trackTitleMarqueeLabel.intrinsicContentSize.height + trackDetailsMarqueeLabel.intrinsicContentSize.height
		
		let labelStackView = UIStackView(arrangedSubviews: [trackTitleMarqueeLabel, trackDetailsMarqueeLabel])
		labelStackView.axis = .vertical
		labelStackView.distribution = .fillProportionally
		
		labelStackView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: height)
		
		super.init(wrappedView: labelStackView, isPresentedVC:isPresentedVC, representingIndex:representingIndex)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
        if useSmallFont {
            wrappedView.frame = view.bounds.insetBy(dx: 0, dy: 5)
        } else {
            wrappedView.frame = view.bounds
        }
	}
	
	private static func getLabelStringsFromTrack(_ track:AudioTrack?) -> (titleText:String, detailsText:String) {
		let titleText = track?.trackTitle ?? "Nothing"
		let detailsText = "\(track?.albumArtist ?? "To")  —  \(track?.albumTitle ?? "Play")"
		return (titleText, detailsText)
	}
	
	private override func refreshViews(_ track: AudioTrack?) {
		let labelStrings = LabelStackWrapperViewController.getLabelStringsFromTrack(track)
		func updateLabel(_ label:MarqueeLabel, text:String) {
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
