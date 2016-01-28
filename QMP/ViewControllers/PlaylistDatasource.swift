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
		super.init()
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
		return UITableViewCell()
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
			
		default:
			break
		}
	}
	
}

