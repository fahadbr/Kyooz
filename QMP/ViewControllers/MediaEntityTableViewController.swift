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

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(NibContainer.mediaCollectionTableViewCellNib, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
        tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
        tableView.registerClass(SearchHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SearchResultsHeaderView.reuseIdentifier)
        
        let control = UISegmentedControl(items: subGroups.map({ $0.name }))
        control.tintColor = ThemeHelper.defaultTintColor
        
        control.apportionsSegmentWidthsByContent = true
        control.addTarget(self, action: "groupingTypeDidChange:", forControlEvents: UIControlEvents.ValueChanged)
        control.selectedSegmentIndex = 0
        if control.frame.size.width < tableView.frame.width {
            headerView.addSubview(control)
            control.translatesAutoresizingMaskIntoConstraints = false
            control.centerXAnchor.constraintEqualToAnchor(headerView.centerXAnchor).active = true
            control.centerYAnchor.constraintEqualToAnchor(headerView.centerYAnchor).active = true
            return
        }
        
        let scrollView = UIScrollView(frame: headerView.bounds)
        scrollView.contentSize = control.frame.size
        
        scrollView.addSubview(control)
        control.frame.origin = CGPoint.zero
        scrollView.scrollsToTop = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        headerView.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.centerYAnchor.constraintEqualToAnchor(headerView.centerYAnchor).active = true
        scrollView.leftAnchor.constraintEqualToAnchor(headerView.layoutMarginsGuide.leftAnchor).active = true
        scrollView.rightAnchor.constraintEqualToAnchor(headerView.layoutMarginsGuide.rightAnchor).active = true
        scrollView.heightAnchor.constraintEqualToConstant(headerHeight).active = true
        
        popGestureRecognizer.enabled = !isBaseLevel
    }
    
    
    private var collectionVC:LibraryGroupCollectionViewController!
    
    private func addCollectionViewControl() {
        collectionVC = LibraryGroupCollectionViewController(items: subGroups)
        collectionVC.view.frame = view.bounds
        collectionVC.view.frame.size.height = collectionVC.estimatedHeight + 60

        tableView.tableHeaderView = collectionVC.view
        addChildViewController(collectionVC)
        collectionVC.didMoveToParentViewController(self)
        collectionVC.collectionView?.scrollsToTop = false
    }
    
    
    func groupingTypeDidChange(sender:UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        let selectedGroup = subGroups[index]
        
        if isBaseLevel {
            sourceData = MediaQuerySourceData(filterQuery: selectedGroup.baseQuery, libraryGrouping: selectedGroup)
        } else {
			if var groupMutableSourceData = sourceData as? GroupMutableAudioEntitySourceData {
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
                datasourceDelegate = KyoozPlaylistDSD(sourceData: sourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: self)
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
        
        if tableView.editing {
            delegate = AudioEntitySelectorDSD(sourceData: sourceData, tableView: tableView)
        }

    }

    
    //MARK: - Overriding MediaItemTableViewController methods
    override func getMediaItemsForIndexPath(indexPath: NSIndexPath) -> [AudioTrack] {
        return sourceData.getTracksAtIndex(indexPath)
    }

    
}
