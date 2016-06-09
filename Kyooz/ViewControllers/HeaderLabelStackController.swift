//
//  HeaderLabelStackController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/8/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class HeaderLabelStackController: UIViewController {
	
	enum LabelConfiguration:Int { case AlbumArtist, TotalCollectionDuration, AlbumDetails, CollectionCount }
	
	static let labelConfigsMap:[LibraryGrouping:[LabelConfiguration]] = [
		LibraryGrouping.Albums : [.AlbumArtist, .TotalCollectionDuration, .AlbumDetails],
		LibraryGrouping.Compilations : [.AlbumArtist, .TotalCollectionDuration, .AlbumDetails],
		LibraryGrouping.Podcasts : [.AlbumArtist, .TotalCollectionDuration, .AlbumDetails],
	]
	
	static let defaultLabelConfigurations:[LabelConfiguration] = [.TotalCollectionDuration, .CollectionCount]
    
    typealias TextStyle = (font:UIFont?, color:UIColor)
    
    let labelStackView:UIStackView
    let labels:[UILabel]
	
	private let sourceData:AudioEntitySourceData
	private let labelConfigurations:[LabelConfiguration]
    
	init(sourceData:AudioEntitySourceData) {
        var labels = [UILabel]()
        let mainDetailLabelStyle:TextStyle = (UIFont(name: ThemeHelper.defaultFontNameBold, size: ThemeHelper.defaultFontSize - 1), ThemeHelper.defaultFontColor)
        let subDetailLabelStyle:TextStyle = (ThemeHelper.smallFontForStyle(.Normal), UIColor.lightGrayColor())
        func createLabel(labelNumber:Int) -> UILabel {
            let textStyle = labelNumber == 0 ? mainDetailLabelStyle : subDetailLabelStyle
            let label = UILabel()
            label.font = textStyle.font
            label.textColor = textStyle.color
            label.textAlignment = .Center
            return label
        }
		
		let labelConfigs:[LabelConfiguration]
		if let parentGroup = sourceData.parentGroup, let configsFromMap = HeaderLabelStackController.labelConfigsMap[parentGroup] {
			labelConfigs = configsFromMap
		} else {
			labelConfigs = HeaderLabelStackController.defaultLabelConfigurations
		}
        
        for i in 0..<labelConfigs.count {
            labels.append(createLabel(i))
        }
		
		self.labelConfigurations = labelConfigs
		self.sourceData = sourceData
        self.labels = labels
        
        labelStackView = UIStackView(arrangedSubviews: labels)
        labelStackView.axis = .Vertical
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = labelStackView
		
		guard let tracks = sourceData.entities as? [AudioTrack], let track = tracks.first else { return }
		
		
		let trackString = " Tracks"
		let trackCountString = "\(tracks.count) \(tracks.count == 1 ? trackString.withoutLast() : trackString)"
		
		for (labelNumber, labelConfig) in labelConfigurations.enumerate() {
			let label = labels[labelNumber]
			switch labelConfig {
				
			case .AlbumArtist:
				label.text = track.albumArtist ?? track.artist
				
			case .AlbumDetails:
				var details = [String]()
				if let releaseDate = track.releaseYear {
					details.append(releaseDate)
				}
				if let genre = track.genre {
					details.append(genre)
				}
				details.append(trackCountString)
				
				label.text = details.joinWithSeparator(" • ")
				
			case .TotalCollectionDuration:
				var duration:NSTimeInterval = 0
				for item in tracks {
					duration += item.playbackDuration
				}
				if let albumDurationString = MediaItemUtils.getLongTimeRepresentation(duration) {
					label.text = "\(albumDurationString)"
				} else {
					label.hidden = true
				}
				
			case .CollectionCount:
				label.text = trackCountString
			}
		}
    }
	
	
}
