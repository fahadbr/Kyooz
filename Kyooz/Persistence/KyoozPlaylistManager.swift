//
//  KyoozPlaylistManager.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/25/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

final class KyoozPlaylistManager : NSObject {
	
	static let instance = KyoozPlaylistManager()
	
    static let PlaylistSetUpdate = "KyoozPlaylistManagerPlaylistSetUpdate"
	private static let listDirectory:String = KyoozUtils.libraryDirectory.stringByAppendingPathComponent("kyoozPlaylists")
	
    private var playlistsSet:NSMutableOrderedSet = NSMutableOrderedSet()
	
	var playlists:NSOrderedSet {
        return playlistsSet
	}
    
    override init() {
        super.init()
        reloadSourceData()
    }
	
	func create(playlist playlist:KyoozPlaylist, withTracks tracks:[AudioTrack]) throws {
		if playlistsSet.containsObject(playlist) {
			let kmvc = KyoozMenuViewController()
			kmvc.menuTitle = "There's already a playlist with the name \(playlist.name). Would you like to overwrite?"
			let overwriteAction = KyoozMenuAction(title: "OVERWRITE,", image: nil, action: {
				do {
					try self.createOrUpdatePlaylist(playlist, withTracks: tracks)
				} catch let error {
					KyoozUtils.showPopupError(withTitle: "Error occurred while saving playlist \(playlist.name)", withThrownError: error, presentationVC: nil)
				}
			})
			kmvc.addActions([overwriteAction])
            KyoozUtils.showMenuViewController(kmvc)
		} else {
			try createOrUpdatePlaylist(playlist, withTracks: tracks)
		}
	}
	
	func update(playlist playlist:KyoozPlaylist, withTracks tracks:[AudioTrack]) throws {
		guard playlistsSet.containsObject(playlist) else {
			throw DataPersistenceError(errorDescription:"Playlist with name \(playlist.name) does not exist")
		}
		try createOrUpdatePlaylist(playlist, withTracks: tracks)
	}
	
    func deletePlaylist(playlist:KyoozPlaylist) throws {
		try playlist.setTracks(nil)
        try updatePlaylistSet(withPlaylist: playlist, actionIsDelete: true)
		ShortNotificationManager.instance.presentShortNotification(withMessage:"Deleted playlist \(playlist.name)")
    }
	
	private func createOrUpdatePlaylist(playlist:KyoozPlaylist, withTracks tracks:[AudioTrack]) throws {
		playlist.count = tracks.count
		
		let oldCount = playlistsSet.count
		
		try playlist.setTracks(tracks)
		try updatePlaylistSet(withPlaylist: playlist, actionIsDelete: false)
		
		let newCount = playlistsSet.count
		ShortNotificationManager.instance.presentShortNotification(withMessage:"Saved \(oldCount < newCount ? "" : "changes to ")playlist: \(playlist.name)")
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
        //
        dispatch_after(KyoozUtils.getDispatchTimeForSeconds(1.0), dispatch_get_main_queue()) {
            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: KyoozPlaylistManager.PlaylistSetUpdate, object: self))
        }
	}
}

extension KyoozPlaylistManager : MutableAudioEntitySourceData {
    
    var sections:[SectionDescription] {
        return [SectionDTO(name: "KYOOZ PLAYLISTS", count: playlistsSet.count)]
    }
    
    var entities:[AudioEntity] {
        return playlistsSet.array as! [KyoozPlaylist]
    }
    
    var libraryGrouping:LibraryGrouping {
		return LibraryGrouping.Playlists
    }
	
	var parentGroup:LibraryGrouping? {
		return nil
	}
	
	var parentCollection:AudioTrackCollection? {
		return nil
	}
	
    func reloadSourceData() {
        guard let object = NSKeyedUnarchiver.unarchiveObjectWithFile(KyoozPlaylistManager.listDirectory) else {
            Logger.debug("couldnt find playlist set in list directory")
			guard NSKeyedArchiver.archiveRootObject(playlistsSet, toFile: KyoozPlaylistManager.listDirectory) else {
				Logger.error("couldn't save kyooz playlist set")
				return
			}
            return
        }
        
        guard let set = object as? NSMutableOrderedSet else {
            Logger.debug("object is not a mutable set")
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
    
    func deleteEntitiesAtIndexPaths(indexPaths: [NSIndexPath]) throws {
		
        let sortedIndexPaths = indexPaths.sort() { $0.row > $1.row }
        for indexPath in sortedIndexPaths {
            guard let playlist = playlistsSet.objectAtIndex(indexPath.row) as? KyoozPlaylist else {
                return
            }
            try deletePlaylist(playlist)
        }
    }
    
    func insertEntities(entities: [AudioEntity], atIndexPath indexPathToInsert: NSIndexPath) throws -> Int {
        throw KyoozError(errorDescription: "unsupported implementation")
    }
    
    func moveEntity(fromIndexPath originalIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) throws {
        //reordering is not supported
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
    
    func artworkImage(forSize size: CGSize) -> UIImage? {
        return ImageUtils.mergeArtwork(forTracks: tracks, usingSize: size)
    }
    
}

func ==(lhs:KyoozPlaylist, rhs:KyoozPlaylist) -> Bool {
    return lhs.hash == rhs.hash
}


