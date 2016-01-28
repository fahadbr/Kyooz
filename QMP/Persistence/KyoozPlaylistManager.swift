//
//  KyoozPlaylistManager.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/25/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

final class KyoozPlaylistManager {
	
	static let instance = KyoozPlaylistManager()
	
	static let listDirectory:String = KyoozUtils.libraryDirectory.stringByAppendingPathComponent("kyoozPlaylists")
	
	private lazy var playlistsSet:NSMutableOrderedSet = NSKeyedUnarchiver.unarchiveObjectWithFile(KyoozPlaylistManager.listDirectory) as? NSMutableOrderedSet ?? NSMutableOrderedSet()
	
	var playlists:NSOrderedSet {
		return playlistsSet
	}
	
	func createOrUpdatePlaylist(playlist:KyoozPlaylist, withTracks tracks:[AudioTrack]) throws {
		playlist.count = tracks.count
		guard NSKeyedArchiver.archiveRootObject(tracks as NSArray, toFile: playlist.name) else {
			throw DataPersistenceError(errorDescription: "failed to persist the tracks for playlist \(playlist.name)")
		}
		
		guard NSKeyedArchiver.archiveRootObject(playlistsSet, toFile: KyoozPlaylistManager.listDirectory) else {
			throw DataPersistenceError(errorDescription: "failed update track count for playlist \(playlist.name)")
		}
		
		playlistsSet.addObject(playlist)
	}
	
	
}

final class KyoozPlaylist : NSObject, NSSecureCoding {
	
	static let nameKey = "kyoozPlaylist.name"
	static let countKey = "kyoozPlaylist.count"
	
	static func supportsSecureCoding() -> Bool {
		return true
	}
	
	override var hash:Int {
		return name.hash
	}
	
	override var hashValue:Int {
		return name.hashValue
	}
	
	let name:String
	private var count:Int = 0
	
	init(name:String) {
		self.name = name
	}
	
	init?(coder aDecoder: NSCoder) {
		guard let persistedName = aDecoder.decodeObjectOfClass(NSString.self, forKey: KyoozPlaylist.nameKey) as? String else {
			name = "Unknown"
			count = 0
			return
		}
		
		count = aDecoder.decodeIntegerForKey(KyoozPlaylist.countKey)
		name = persistedName
	}
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(name, forKey: KyoozPlaylist.nameKey)
		aCoder.encodeInteger(count, forKey: KyoozPlaylist.countKey)
	}
	
}
