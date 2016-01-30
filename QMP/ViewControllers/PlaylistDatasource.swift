//
//  PlaylistDatasource.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/25/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class PlaylistDatasource : NSObject, UITableViewDataSource, UITableViewDelegate {
	
	private var kyoozPlaylistManager = KyoozPlaylistManager.instance
	
	let itunesLibraryPlaylists:[MPMediaPlaylist]
	let kyoozPlaylists:NSOrderedSet
	
	let mediaEntityTVC:MediaEntityTableViewController
	
	init(itunesLibraryPlaylists:[MPMediaPlaylist], mediaEntityTVC:MediaEntityTableViewController) {
		self.itunesLibraryPlaylists = itunesLibraryPlaylists
		self.mediaEntityTVC = mediaEntityTVC
		kyoozPlaylists = kyoozPlaylistManager.playlists
        if kyoozPlaylists.count != 0 {
            mediaEntityTVC.tableView.estimatedSectionHeaderHeight = 40
            mediaEntityTVC.tableView.sectionHeaderHeight = 40
        }
		super.init()
	}
    
    deinit {
        Logger.debug("deinit playlistDS")
    }
	
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return kyoozPlaylists.count == 0 ? 1 : 2
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return itunesLibraryPlaylists.count
		case 1:
			return kyoozPlaylists.count
		default:
			return 0
		}
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let audioCell = tableView.dequeueReusableCellWithIdentifier(MediaCollectionTableViewCell.reuseIdentifier) as? MediaCollectionTableViewCell else {
            return UITableViewCell()
        }
        
        switch indexPath.section {
        case 0:
            let entity = itunesLibraryPlaylists[indexPath.row]
            audioCell.configureCellForItems(entity, mediaGroupingType: MPMediaGrouping.Playlist)
        case 1:
            guard let playlist = kyoozPlaylists.objectAtIndex(indexPath.row) as? KyoozPlaylist else {
                return audioCell
            }
            audioCell.titleLabel.text = playlist.name
            audioCell.detailsLabel.text = "\(playlist.count) Track\(playlist.count > 1 ? "s" : "")"
            
        default:
            break
        }

        audioCell.isNowPlayingItem = false
        audioCell.indexPath = indexPath
        audioCell.delegate = mediaEntityTVC
        
        
        return audioCell
        
            
	}
	
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		guard let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SearchResultsHeaderView.reuseIdentifier) as? SearchHeaderFooterView else {
			return nil
		}
		view.initializeHeaderView()
		
		if let headerView = view.headerView {
			headerView.headerTitleLabel.text = section == 0 ? "iTunes Playlists" : "Kyooz Playlists"
			headerView.disclosureContainerView.hidden = true
		}
		return view
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		switch indexPath.section {
		case 0:
			mediaEntityTVC.tableView(tableView, didSelectRowAtIndexPath: indexPath)
		case 1:
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            guard let kPlaylist = kyoozPlaylists.objectAtIndex(indexPath.row) as? KyoozPlaylist else {
                Logger.error("object at index \(indexPath.row) was not a kyooz playlist")
                return
            }
            
			let vc = UIStoryboard.albumTrackTableViewController()
            vc.filterQuery = DummyQuery(items: kPlaylist.getTracks() as! [MPMediaItem])
            vc.libraryGroupingType = LibraryGrouping.Songs
            ContainerViewController.instance.pushViewController(vc)
            break
		default:
			break
		}
	}
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section != 0
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            do {
                try kyoozPlaylistManager.deletePlaylist(kyoozPlaylists[indexPath.row] as! KyoozPlaylist)
            } catch let error {
                if let dataError = error as? DataPersistenceError {
                    Logger.debug("error while deleting \(dataError.errorDescription)")
                } else {
                    Logger.debug("error while deleting \((error as NSError).localizedDescription)")
                }
				tableView.editing = false
                return
            }
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            if kyoozPlaylists.count == 0 {
                tableView.deleteSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
                tableView.sectionHeaderHeight = 0
                tableView.estimatedSectionHeaderHeight = 0
                KyoozUtils.doInMainQueueAsync() { [mediaEntityTVC = self.mediaEntityTVC] in
                    mediaEntityTVC.reloadAllData()
                }
            }
            tableView.endUpdates()
        }
    }
    
    //MARK: - class functions
    func getMediaItemsFromKyoozPlaylistAtIndex(index:Int) -> [AudioTrack] {
        return kyoozPlaylists[index].getTracks()
    }
    
    
	
}

final class DummyQuery : MPMediaQuery {
    
    private let _items:[MPMediaItem]
    
    init(items:[MPMediaItem]) {
        _items = items
        super.init(filterPredicates: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var items:[MPMediaItem]! {
        return _items
    }
    
    override var collections:[MPMediaItemCollection]! {
        return [MPMediaItemCollection(items: _items)]
    }
    
}

