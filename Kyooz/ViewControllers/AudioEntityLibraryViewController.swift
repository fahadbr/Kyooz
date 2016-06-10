//
//  AudioEntityLibraryViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/8/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class AudioEntityLibraryViewController : AudioEntityHeaderViewController {
    
    static let navigationMenuButton:UIButton = {
        let button = ListButtonView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        button.showBullets = false
        button.pathTransform = CGAffineTransformMakeTranslation(10, 0)
        button.color = ThemeHelper.defaultFontColor
        button.alignRight = true
        button.addTarget(ContainerViewController.instance, action: #selector(ContainerViewController.presentKyoozNavigationController), forControlEvents: .TouchUpInside)
        return button
    }()
    
    static let fadeInAnimation = KyoozUtils.fadeInAnimationWithDuration(0.4)
	
	var isBaseLevel:Bool = false
	
	override var shouldAnimateInArtwork: Bool {
		return _shouldAnimateInArtwork
	}
	
	override var subGroups:[LibraryGrouping]? {
		return isBaseLevel ? LibraryGrouping.allMusicGroupings : sourceData.parentGroup?.subGroupsForNextLevel
	}
	
	private var _shouldAnimateInArtwork:Bool = false
	
	private var reuseIdentifier:String {
		if useCollapsableHeader && sourceData.parentGroup !== LibraryGrouping.Playlists {
			return AlbumTrackTableViewCell.reuseIdentifier
		}
		
		if sourceData.libraryGrouping.usesArtwork {
			return ImageTableViewCell.reuseIdentifier
		}
		return MediaCollectionTableViewCell.reuseIdentifier
	}
	
	private let tableFooterView = KyoozTableFooterView()
	
	override func viewDidLoad() {
        //if there is only one song for the current group then change the grouping type to be songs
        //must be done before call to super.viewDidLoad() bc the Util Header VC will be configured in that call
        let entities = sourceData.entities
        if sourceData.libraryGrouping !== LibraryGrouping.Songs && entities.count == 1 && ((entities.first as? AudioTrackCollection)?.tracks.count == 1) ?? false {
            if let sd = sourceData as? GroupMutableAudioEntitySourceData {
                sd.libraryGrouping = LibraryGrouping.Songs
            }
        }
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.dynamicType.navigationMenuButton)
        
		tableView.registerNib(NibContainer.mediaCollectionTableViewCellNib, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
		tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
		tableView.registerNib(NibContainer.albumTrackTableViewCellNib, forCellReuseIdentifier: AlbumTrackTableViewCell.reuseIdentifier)
		tableView.registerClass(SearchHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SearchResultsHeaderView.reuseIdentifier)
        
        KyoozUtils.doInMainQueueAsync() {
            self.applyDataSourceAndDelegate()
            self.reloadAllData()
        }
    }
	
	
	//MARK: - Class functions
	
	override func reloadSourceData() {
		super.reloadSourceData()
		let count = sourceData.entities.count
		let groupName = count == 1 ? sourceData.libraryGrouping.name.withoutLast() : sourceData.libraryGrouping.name
		tableFooterView.text = "\(count) \(groupName)"
		tableView.tableFooterView = tableFooterView
	}
    
    override func reloadTableViewData() {
		_shouldAnimateInArtwork = false
        super.reloadTableViewData()
		KyoozUtils.doInMainQueueAsync() {
			self._shouldAnimateInArtwork = true
		}
    }
	
	override func addCustomMenuActions(indexPath: NSIndexPath, tracks:[AudioTrack], menuController:KyoozMenuViewController) {
		if sourceData is MutableAudioEntitySourceData || (LibraryGrouping.Playlists == sourceData.libraryGrouping && sourceData[indexPath] is KyoozPlaylist) {
			menuController.addActions([KyoozMenuAction(title: "DELETE", image: nil, action: {[sourceData = self.sourceData] in
				KyoozUtils.confirmAction("Are you sure you want to delete \(sourceData[indexPath].titleForGrouping(sourceData.libraryGrouping) ?? "this item")?") {
					self.datasourceDelegate?.tableView?(self.tableView, commitEditingStyle: .Delete, forRowAtIndexPath: indexPath)
				}
			})])
		}
	}
	
	
	func groupingTypeDidChange(selectedGroup:LibraryGrouping) {
		guard let subGroups = self.subGroups else { return }
		
		if isBaseLevel {
            NSUserDefaults.standardUserDefaults().setInteger(subGroups.indexOf(selectedGroup) ?? 0, forKey: UserDefaultKeys.AllMusicBaseGroup)
		}
		
		if let groupMutableSourceData = sourceData as? GroupMutableAudioEntitySourceData {
			groupMutableSourceData.libraryGrouping = selectedGroup
		}
		tableView.contentOffset.y = -tableView.contentInset.top
		applyDataSourceAndDelegate()
		reloadAllData()
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
        tableView.layer.addAnimation(self.dynamicType.fadeInAnimation, forKey: nil)
	}
    
    override func registerForNotifications() {
        super.registerForNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AudioEntityLibraryViewController.reloadAllData),
                                                         name: KyoozPlaylistManager.PlaylistSetUpdate, object: KyoozPlaylistManager.instance)
    }
	
}
