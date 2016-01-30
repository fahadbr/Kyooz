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
	
	private static let listDirectory:String = KyoozUtils.libraryDirectory.stringByAppendingPathComponent("kyoozPlaylists")
	
    private lazy var playlistsSet:NSMutableOrderedSet = {
        guard let object = NSKeyedUnarchiver.unarchiveObjectWithFile(KyoozPlaylistManager.listDirectory) else {
            Logger.error("couldnt find playlist set in list directory")
            return NSMutableOrderedSet()
        }
        
        guard let set = object as? NSMutableOrderedSet else {
            Logger.error("object is not a mutable set")
            return NSMutableOrderedSet()
        }
        return set
    }()
	
	var playlists:NSOrderedSet {
		return playlistsSet
	}
	
	func createOrUpdatePlaylist(playlist:KyoozPlaylist, withTracks tracks:[AudioTrack]) throws {
		playlist.count = tracks.count
		try playlist.setTracks(tracks)
		try updatePlaylistSet(withPlaylist: playlist, actionIsDelete: false)
        ShortNotificationManager.instance.presentShortNotificationWithMessage("Saved playlist with name \(playlist.name)", withSize: .Small)
	}
	
    func deletePlaylist(playlist:KyoozPlaylist) throws {
		try playlist.setTracks(nil)
        try updatePlaylistSet(withPlaylist: playlist, actionIsDelete: true)
		ShortNotificationManager.instance.presentShortNotificationWithMessage("Deleted playlist \(playlist.name)", withSize: .Small)
    }
	
	private func updatePlaylistSet(withPlaylist playlist:KyoozPlaylist, actionIsDelete:Bool) throws {
		func addOrRemove(remove:Bool) {
			if remove {
				playlistsSet.removeObject(playlist)
			} else {
				playlistsSet.addObject(playlist)
			}
		}
		addOrRemove(actionIsDelete)
		guard NSKeyedArchiver.archiveRootObject(playlistsSet, toFile: KyoozPlaylistManager.listDirectory) else {
			addOrRemove(!actionIsDelete)
			throw DataPersistenceError(errorDescription: "Failed update playlist master file for playlist \(playlist.name)")
		}
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
    
    override func isEqual(object: AnyObject?) -> Bool {
        guard let otherPlaylist = object as? KyoozPlaylist else {
            return false
        }
        return otherPlaylist.hash == hash
    }
    
	
	let name:String
	private (set) var count:Int = 0
	private var tracks:[AudioTrack]!
	
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
	
	private func playlistTracksFileName() -> String {
		return KyoozUtils.libraryDirectory.stringByAppendingPathComponent(name)
	}
    
    func getTracks() -> [AudioTrack] {
		if tracks == nil {
			tracks = NSKeyedUnarchiver.unarchiveObjectWithFile(playlistTracksFileName()) as? [AudioTrack] ?? [AudioTrack]()
			
		}
		return tracks
    }
	
	private func setTracks(tracks:[AudioTrack]?) throws {
		guard let newTracks = tracks else {
			try NSFileManager.defaultManager().removeItemAtPath(playlistTracksFileName())
			return
		}
		
		guard NSKeyedArchiver.archiveRootObject(newTracks as NSArray, toFile: playlistTracksFileName()) else {
			throw DataPersistenceError(errorDescription: "Failed to save the tracks for playlist \(name)")
		}
	}
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(name, forKey: KyoozPlaylist.nameKey)
		aCoder.encodeInteger(count, forKey: KyoozPlaylist.countKey)
	}
	
}

func ==(lhs:KyoozPlaylist, rhs:KyoozPlaylist) -> Bool {
    return lhs.hash == rhs.hash
}


