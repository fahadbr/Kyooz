//
//  HeaderLabelStackController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/8/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class HeaderLabelStackController: UIViewController {
	
	enum LabelConfiguration:Int { case albumArtist, totalCollectionDuration, albumDetails, collectionCount }
	
	static let labelConfigsMap:[LibraryGrouping:[LabelConfiguration]] = [
		LibraryGrouping.Playlists : [.collectionCount, .totalCollectionDuration]
	]
	
	static let defaultLabelConfigurations:[LabelConfiguration] = [.albumArtist, .totalCollectionDuration, .albumDetails]
    
    typealias TextStyle = (font:UIFont?, color:UIColor)
    
    let labelStackView:UIStackView
    let labels:[UILabel]
	
	private let sourceData:AudioEntitySourceData
	private let labelConfigurations:[LabelConfiguration]
    
	init(sourceData:AudioEntitySourceData) {
        var labels = [UILabel]()
        let mainDetailLabelStyle:TextStyle = (UIFont(name: ThemeHelper.defaultFontNameBold, size: ThemeHelper.defaultFontSize - 1), ThemeHelper.defaultFontColor)
        let subDetailLabelStyle:TextStyle = (ThemeHelper.smallFontForStyle(.normal), UIColor.lightGray)
        func createLabel(_ labelNumber:Int, config:LabelConfiguration) -> UILabel {
            let textStyle = config == .albumArtist ? mainDetailLabelStyle : subDetailLabelStyle
            let label = UILabel()
            label.font = textStyle.font
            label.textColor = textStyle.color
            label.textAlignment = .center
            label.layer.shouldRasterize = true
            label.layer.rasterizationScale = UIScreen.main.scale
            return label
        }
		
		let labelConfigs:[LabelConfiguration]
		if let parentGroup = sourceData.parentGroup, let configsFromMap = HeaderLabelStackController.labelConfigsMap[parentGroup] {
			labelConfigs = configsFromMap
		} else {
			labelConfigs = HeaderLabelStackController.defaultLabelConfigurations
		}
        
        for (i, config) in labelConfigs.enumerated() {
            labels.append(createLabel(i, config:config))
        }
		
		self.labelConfigurations = labelConfigs
		self.sourceData = sourceData
        self.labels = labels
        
        labelStackView = UIStackView(arrangedSubviews: labels)
        labelStackView.axis = .vertical
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = labelStackView
		
		guard let tracks = sourceData.entities as? [AudioTrack], let track = tracks.first else { return }
		
		
		let trackString = "Tracks"
		let trackCountString = "\(tracks.count) \(tracks.count == 1 ? trackString.withoutLast() : trackString)"
		
		for (labelNumber, labelConfig) in labelConfigurations.enumerated() {
			let label = labels[labelNumber]
			switch labelConfig {
				
			case .albumArtist:
				label.text = track.albumArtist ?? track.artist
				
			case .albumDetails:
				var details = [String]()
				if let releaseDate = track.releaseYear {
					details.append(releaseDate)
				}
				if let genre = track.genre {
					details.append(genre)
				}
				details.append(trackCountString)
				
				label.text = details.joined(separator: " • ")
				
			case .totalCollectionDuration:
				var duration:TimeInterval = 0
				for item in tracks {
					duration += item.playbackDuration
				}
				if let albumDurationString = MediaItemUtils.getLongTimeRepresentation(duration) {
					label.text = "\(albumDurationString)"
				} else {
					label.isHidden = true
				}
				
			case .collectionCount:
				label.text = trackCountString
			}
		}
    }
	
	
}
