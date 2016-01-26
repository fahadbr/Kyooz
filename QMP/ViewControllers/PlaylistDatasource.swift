//
//  PlaylistDatasource.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/25/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class PlaylistDatasource : NSObject, UITableViewDataSource {
	
	let itunesLibraryPlaylists:[MPMediaPlaylist]
	let kyoozPlaylists:[String:[AudioTrack]]
	
	init(itunesLibraryPlaylists:[MPMediaPlaylist]) {
		self.itunesLibraryPlaylists = itunesLibraryPlaylists
		kyoozPlaylists = [String:[AudioTrack]]()
	}
	
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 0
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return UITableViewCell()
	}
	
}

