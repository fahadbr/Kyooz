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
        playlistsSet.addObject(playlist)
        
		guard NSKeyedArchiver.archiveRootObject(tracks as NSArray, toFile: KyoozUtils.libraryDirectory.stringByAppendingPathComponent(playlist.name)) else {
			throw DataPersistenceError(errorDescription: "Failed to save the tracks for playlist \(playlist.name)")
		}
		
		guard NSKeyedArchiver.archiveRootObject(playlistsSet, toFile: KyoozPlaylistManager.listDirectory) else {
			throw DataPersistenceError(errorDescription: "Failed update playlist master file for playlist \(playlist.name)")
		}
		

        Logger.debug("saved playlist with name \(playlist.name)")
	}
	
    func deletePlaylist(playlist:KyoozPlaylist) throws {
        try NSFileManager.defaultManager().removeItemAtPath(KyoozUtils.libraryDirectory.stringByAppendingPathComponent(playlist.name))
        playlistsSet.removeObject(playlist)
        guard NSKeyedArchiver.archiveRootObject(playlistsSet, toFile: KyoozPlaylistManager.listDirectory) else {
            playlistsSet.addObject(playlist)
            throw DataPersistenceError(errorDescription: "Failed update playlist master file for playlist \(playlist.name)")
        }
        Logger.debug("deleted playlist \(playlist.name)")
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
    
    func getTracks() -> [AudioTrack] {
        return NSKeyedUnarchiver.unarchiveObjectWithFile(KyoozUtils.libraryDirectory.stringByAppendingPathComponent(name)) as? [AudioTrack] ?? [AudioTrack]()
    }
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(name, forKey: KyoozPlaylist.nameKey)
		aCoder.encodeInteger(count, forKey: KyoozPlaylist.countKey)
	}
	
}

func ==(lhs:KyoozPlaylist, rhs:KyoozPlaylist) -> Bool {
    return lhs.hash == rhs.hash
}


