//
//  KyoozPlaylistManager.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/25/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

final class KyoozPlaylistManager  {
	
	static let instance = KyoozPlaylistManager()
	
	private static let listDirectory:String = KyoozUtils.libraryDirectory.stringByAppendingPathComponent("kyoozPlaylists")
	
    private var playlistsSet:NSMutableOrderedSet = NSMutableOrderedSet()
	
	var playlists:NSOrderedSet {
        return playlistsSet
	}
    
    init() {
        reloadSourceData()
    }
	
	func createOrUpdatePlaylist(playlist:KyoozPlaylist, withTracks tracks:[AudioTrack]) throws {
		playlist.count = tracks.count
        let oldCount = playlistsSet.count
		try playlist.setTracks(tracks)
		try updatePlaylistSet(withPlaylist: playlist, actionIsDelete: false)
        let newCount = playlistsSet.count
        ShortNotificationManager.instance.presentShortNotificationWithMessage("Saved \(oldCount < newCount ? "" : "changes to ")playlist: \(playlist.name)", withSize: .Small)
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

extension KyoozPlaylistManager : AudioEntitySourceData {
    
    var sections:[SectionDescription] {
        return [SectionDTO(name: "KYOOZ PLAYLISTS", count: playlistsSet.count)]
    }
    
    var entities:[AudioEntity] {
        return playlistsSet.array as! [KyoozPlaylist]
    }
    
    var libraryGrouping:LibraryGrouping {
        get {
            return LibraryGrouping.Playlists
        } set { } //setter does nothing
    }
    
    func reloadSourceData() {
        guard let object = NSKeyedUnarchiver.unarchiveObjectWithFile(KyoozPlaylistManager.listDirectory) else {
            Logger.error("couldnt find playlist set in list directory")
            return
        }
        
        guard let set = object as? NSMutableOrderedSet else {
            Logger.error("object is not a mutable set")
            return
        }
        playlistsSet = set
    }
    
    func sourceDataForIndex(indexPath: NSIndexPath) -> AudioEntitySourceData? {
        guard let playlist = playlistsSet.objectAtIndex(indexPath.row) as? KyoozPlaylist else {
            return nil
        }
        return KyoozPlaylistSourceData(playlist: playlist)
    }
    
    subscript(i:NSIndexPath) -> AudioEntity {
        return playlistsSet.objectAtIndex(i.row) as! KyoozPlaylist
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
    
    private var _tracks:[AudioTrack]! {
        didSet {
            count = _tracks?.count ?? 0
        }
    }
    
    private var playlistTracksFileName : String {
        return KyoozUtils.libraryDirectory.stringByAppendingPathComponent(name)
    }
	
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
	

	
	private func setTracks(tracks:[AudioTrack]?) throws {
		guard let newTracks = tracks else {
			try NSFileManager.defaultManager().removeItemAtPath(playlistTracksFileName)
			return
		}
		
		guard NSKeyedArchiver.archiveRootObject(newTracks as NSArray, toFile: playlistTracksFileName) else {
			throw DataPersistenceError(errorDescription: "Failed to save the tracks for playlist \(name)")
		}
        _tracks = tracks
	}
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(name, forKey: KyoozPlaylist.nameKey)
		aCoder.encodeInteger(count, forKey: KyoozPlaylist.countKey)
	}
	
}

extension KyoozPlaylist : AudioTrackCollection {
    var representativeTrack:AudioTrack? {
        return tracks.first
    }
    
    func titleForGrouping(libraryGrouping:LibraryGrouping) -> String? {
        if libraryGrouping == LibraryGrouping.Playlists {
            return name
        }
        return tracks.first?.titleForGrouping(libraryGrouping)
    }
    
    func persistentIdForGrouping(libraryGrouping:LibraryGrouping) -> UInt64 {
        return tracks.first?.persistentIdForGrouping(libraryGrouping) ?? 0
    }
    
    var tracks:[AudioTrack] {
        if _tracks == nil {
            _tracks = NSKeyedUnarchiver.unarchiveObjectWithFile(playlistTracksFileName) as? [AudioTrack] ?? [AudioTrack]()
        }
        return _tracks
    }
    
    
}

func ==(lhs:KyoozPlaylist, rhs:KyoozPlaylist) -> Bool {
    return lhs.hash == rhs.hash
}


