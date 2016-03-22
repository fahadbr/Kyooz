//
//  AudioEntityLibraryViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/8/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class AudioEntityLibraryViewController : AudioEntityHeaderViewController, UIGestureRecognizerDelegate {
	
	private static let searchButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: RootViewController.instance, action: #selector(RootViewController.activateSearch))
	
	var reuseIdentifier:String {
		if useCollapsableHeader {
			return AlbumTrackTableViewCell.reuseIdentifier
		}
		
		if sourceData.libraryGrouping == LibraryGrouping.Albums {
			return ImageTableViewCell.reuseIdentifier
		}
		return MediaCollectionTableViewCell.reuseIdentifier
	}
	
	
	var testMode = false
	var testDelegate:TestTableViewDataSourceDelegate!
	
	
	var subGroups:[LibraryGrouping] = LibraryGrouping.values {
		didSet {
			isBaseLevel = false
		}
	}
	
	private var isBaseLevel:Bool = true
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.rightBarButtonItem = self.dynamicType.searchButton
		popGestureRecognizer.enabled = !isBaseLevel
		popGestureRecognizer.delegate = self
		
		tableView.registerNib(NibContainer.mediaCollectionTableViewCellNib, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
		tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
		tableView.registerNib(NibContainer.albumTrackTableViewCellNib, forCellReuseIdentifier: AlbumTrackTableViewCell.reuseIdentifier)
		tableView.registerClass(SearchHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SearchResultsHeaderView.reuseIdentifier)
		
		
		if testMode {
			configureTestDelegates()
		} else {
			applyDataSourceAndDelegate()
		}
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AudioEntityLibraryViewController.reloadAllData),
			name: KyoozPlaylistManager.PlaylistSetUpdate, object: KyoozPlaylistManager.instance)
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
	
	
	override func addCustomMenuActions(indexPath: NSIndexPath, menuController:KyoozMenuViewController) {
        if sourceData is MutableAudioEntitySourceData || (LibraryGrouping.Playlists == sourceData.libraryGrouping && sourceData[indexPath] is KyoozPlaylist) {
            menuController.addAction(KyoozMenuAction(title: "Delete", image: nil, action: {_ in
                self.datasourceDelegate?.tableView?(self.tableView, commitEditingStyle: .Delete, forRowAtIndexPath: indexPath)
            }))
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
	
	
	
	//MARK: - GESTURE RECOGNIZER DELEGATE
	final func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if otherGestureRecognizer === popGestureRecognizer {
			return gestureRecognizer === tableView.panGestureRecognizer
		}
		return false
	}
	final func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return false
	}
	
	final func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer === popGestureRecognizer {
			return otherGestureRecognizer === tableView.panGestureRecognizer
		}
		return false
	}
}
