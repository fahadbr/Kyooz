//
//  MediaCollectionTableViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 10/4/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class MediaEntityTableViewController: ParentMediaEntityHeaderViewController {

    
    var subGroups:[LibraryGrouping] = LibraryGrouping.values {
        didSet {
            isBaseLevel = false
        }
    }
    
    private (set) var isBaseLevel:Bool = true
    var headerVC:HeaderViewController!

    override func viewDidLoad() {
        shouldCollapseHeaderView = useCollectionDetailsHeader
        
        tableView.registerNib(NibContainer.mediaCollectionTableViewCellNib, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
        tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
        tableView.registerClass(SearchHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SearchResultsHeaderView.reuseIdentifier)
        
        headerVC = getHeaderViewController()
        headerView.addSubview(headerVC.view)

        headerVC.view.translatesAutoresizingMaskIntoConstraints = false
        headerVC.view.topAnchor.constraintEqualToAnchor(headerView.topAnchor).active = true
        headerVC.view.bottomAnchor.constraintEqualToAnchor(headerView.bottomAnchor).active = true
        headerVC.view.leftAnchor.constraintEqualToAnchor(headerView.leftAnchor).active = true
        headerVC.view.rightAnchor.constraintEqualToAnchor(headerView.rightAnchor).active = true
        addChildViewController(headerVC)
        headerVC.didMoveToParentViewController(self)
		
		headerHeightConstraint.constant = headerVC.height
		maxHeight = headerVC.height
		collapsedTargetOffset = maxHeight - headerVC.minimumHeight
		minHeight = headerVC.minimumHeight
		headerVC.tableView = tableView
		headerVC.sourceData = sourceData
        
        if sourceData is GroupMutableAudioEntitySourceData {
            (headerVC as? UtilHeaderViewController)?.subGroups = subGroups
        }
        
        if let tracks = sourceData.entities as? [AudioTrack], let cdhvc = headerVC as? ArtworkHeaderViewController {
			cdhvc.configureViewWithCollection(tracks)
            tableView.registerNib(NibContainer.albumTrackTableViewCellNib, forCellReuseIdentifier: AlbumTrackTableViewCell.reuseIdentifier)
            KyoozUtils.doInMainQueueAsync() {
                self.updateConstraints()
            }
        }

        super.viewDidLoad()
        popGestureRecognizer.enabled = !isBaseLevel
        
    }
    
    
    private func updateConstraints() {
        if headerVC is ArtworkHeaderViewController {
            headerTopAnchorConstraint.active = false
            headerTopAnchorConstraint = headerView.topAnchor.constraintEqualToAnchor(view.topAnchor)
            headerTopAnchorConstraint.active = true
        }
    }
    
    private func getHeaderViewController() -> HeaderViewController {
        if useCollectionDetailsHeader {
            return UIStoryboard.artworkHeaderViewController()
        }
        return UIStoryboard.utilHeaderViewController()
    }
    
    
    func groupingTypeDidChange(selectedGroup:LibraryGrouping) {
        if isBaseLevel {
            sourceData = MediaQuerySourceData(filterQuery: selectedGroup.baseQuery, libraryGrouping: selectedGroup)
        } else {
			if let groupMutableSourceData = sourceData as? GroupMutableAudioEntitySourceData {
				groupMutableSourceData.libraryGrouping = selectedGroup
			}
        }
        
        applyDataSourceAndDelegate()
        reloadAllData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func addCustomMenuActions(indexPath: NSIndexPath, alertController: UIAlertController) {
        switch sourceData.libraryGrouping {
        case LibraryGrouping.Playlists:
            guard sourceData[indexPath] is KyoozPlaylist else { return }
            alertController.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: {_ in
                self.datasourceDelegate?.tableView?(self.tableView, commitEditingStyle: .Delete, forRowAtIndexPath: indexPath)
            }))
        default:
            break
        }
    }
	
    
    override func applyDataSourceAndDelegate() {
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

    
    //MARK: - Overriding MediaItemTableViewController methods
    override func getMediaItemsForIndexPath(indexPath: NSIndexPath) -> [AudioTrack] {
        return sourceData.getTracksAtIndex(indexPath)
    }

    
}
