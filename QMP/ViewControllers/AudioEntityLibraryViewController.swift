//
//  AudioEntityLibraryViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/8/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class AudioEntityLibraryViewController : AudioEntityHeaderViewController {
	
	var reuseIdentifier:String {
		if useCollapsableHeader {
			return AlbumTrackTableViewCell.reuseIdentifier
		}
		
		if sourceData.libraryGrouping.usesArtwork {
			return ImageTableViewCell.reuseIdentifier
		}
		return MediaCollectionTableViewCell.reuseIdentifier
	}
	
	
	var testMode = false
	var testDelegate:TestTableViewDataSourceDelegate!
	
	
	var subGroups:[LibraryGrouping] = LibraryGrouping.allMusicGroupings
	var isBaseLevel:Bool = true
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
        let homeButton = HomeButtonView(frame: CGRect(x: 0, y: 0, width: 45, height: 45))
        
        homeButton.addTarget(self, action: #selector(self.goHome), forControlEvents: .TouchUpInside)
        let button = UIBarButtonItem(customView: homeButton)
        homeButton.alpha = ThemeHelper.defaultButtonTextAlpha
        navigationItem.rightBarButtonItem = button
        
		tableView.registerNib(NibContainer.mediaCollectionTableViewCellNib, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
		tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
		tableView.registerNib(NibContainer.albumTrackTableViewCellNib, forCellReuseIdentifier: AlbumTrackTableViewCell.reuseIdentifier)
		tableView.registerClass(SearchHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SearchResultsHeaderView.reuseIdentifier)
		
		
		if testMode {
			configureTestDelegates()
		} else {
            KyoozUtils.doInMainQueueAsync() {
                self.applyDataSourceAndDelegate()
                self.reloadAllData()
            }
		}
		
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AudioEntityLibraryViewController.reloadAllData),
                                                         name: KyoozPlaylistManager.PlaylistSetUpdate, object: KyoozPlaylistManager.instance)
    }
    
    func goHome() {
        navigationController?.popToRootViewControllerAnimated(true)
    }
	
	private func configureTestDelegates() {
		testDelegate = TestTableViewDataSourceDelegate()
		tableView.dataSource = testDelegate
		tableView.delegate = testDelegate
		tableView.sectionHeaderHeight = 40
		tableView.rowHeight = 60
	}
	
	//MARK: - Class functions
	
	func groupingTypeDidChange(selectedGroup:LibraryGrouping) {
		if isBaseLevel {
			sourceData = MediaQuerySourceData(filterQuery: selectedGroup.baseQuery, libraryGrouping: selectedGroup)
		} else {
			if let groupMutableSourceData = sourceData as? GroupMutableAudioEntitySourceData {
				groupMutableSourceData.libraryGrouping = selectedGroup
			}
		}
		tableView.contentOffset.y = -tableView.contentInset.top
		applyDataSourceAndDelegate()
		reloadAllData()
	}
	
	
    override func addCustomMenuActions(indexPath: NSIndexPath, tracks:[AudioTrack], menuController:KyoozMenuViewController) {
        if sourceData is MutableAudioEntitySourceData || (LibraryGrouping.Playlists == sourceData.libraryGrouping && sourceData[indexPath] is KyoozPlaylist) {
            menuController.addActions([KyoozMenuAction(title: "DELETE", image: nil, action: {_ in
                self.datasourceDelegate?.tableView?(self.tableView, commitEditingStyle: .Delete, forRowAtIndexPath: indexPath)
            })])
        }
	}
	
	
	func applyDataSourceAndDelegate() {
		switch sourceData.libraryGrouping {
		case LibraryGrouping.Songs:
			if sourceData is KyoozPlaylistSourceData {
				datasourceDelegate = EditableAudioTrackDSD(sourceData: sourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: self)
			} else {
				datasourceDelegate = AudioTrackDSD(sourceData: sourceData, reuseIdentifier:  reuseIdentifier, audioCellDelegate: self)
			}
		case LibraryGrouping.Playlists:
			let playlistSourceData = MediaQuerySourceData(filterQuery: LibraryGrouping.Playlists.baseQuery, libraryGrouping: LibraryGrouping.Playlists, singleSectionName: "ITUNES PLAYLISTS")
			let playlistDSD = AudioTrackCollectionDSD(sourceData:playlistSourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: self)
			let kPlaylistDSD = KyoozPlaylistManagerDSD(sourceData: KyoozPlaylistManager.instance, reuseIdentifier: reuseIdentifier, audioCellDelegate: self)
			let delegator = AudioEntityDSDSectionDelegator(datasources: [kPlaylistDSD, playlistDSD])
			
			sourceData = delegator
			datasourceDelegate = delegator
		default:
			datasourceDelegate = AudioTrackCollectionDSD(sourceData:sourceData, reuseIdentifier:reuseIdentifier, audioCellDelegate:self)
		}
	}
	
}
