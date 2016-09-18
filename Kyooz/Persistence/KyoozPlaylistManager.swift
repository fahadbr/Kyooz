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
	
    static let PlaylistSetUpdate = Notification.Name(rawValue:"KyoozPlaylistManagerPlaylistSetUpdate")
    fileprivate static let listDirectory: String = KyoozUtils.libraryDirectory.appendingPathComponent("kyoozPlaylists").path
	
    fileprivate var playlistsSet:NSMutableOrderedSet = NSMutableOrderedSet()
	
	var playlists:NSOrderedSet {
        return playlistsSet
	}
    
    override init() {
        super.init()
        reloadSourceData()
    }
	
	func create(playlist:KyoozPlaylist, withTracks tracks:[AudioTrack]) throws {
		if playlistsSet.contains(playlist) {
			let b = MenuBuilder()
                .with(title: "There's already a playlist with the name \(playlist.name). Would you like to overwrite?")
                .with(options:KyoozMenuAction(title: "OVERWRITE,") {
                    do {
                        try self.createOrUpdatePlaylist(playlist, withTracks: tracks)
                    } catch let error {
                        KyoozUtils.showPopupError(withTitle: "Error occurred while saving playlist \(playlist.name)", withThrownError: error, presentationVC: nil)
                    }
                })
			
            KyoozUtils.showMenuViewController(b.viewController)
		} else {
			try createOrUpdatePlaylist(playlist, withTracks: tracks)
		}
	}
	
	func update(playlist:KyoozPlaylist, withTracks tracks:[AudioTrack]) throws {
		guard playlistsSet.contains(playlist) else {
			throw DataPersistenceError(errorDescription:"Playlist with name \(playlist.name) does not exist")
		}
		try createOrUpdatePlaylist(playlist, withTracks: tracks)
	}
	
    func deletePlaylist(_ playlist:KyoozPlaylist) throws {
		try playlist.setTracks(nil)
        try updatePlaylistSet(withPlaylist: playlist, actionIsDelete: true)
		ShortNotificationManager.instance.presentShortNotification(withMessage:"Deleted playlist \(playlist.name)")
    }
	
	fileprivate func createOrUpdatePlaylist(_ playlist:KyoozPlaylist, withTracks tracks:[AudioTrack]) throws {
		playlist.count = tracks.count
		
		let oldCount = playlistsSet.count
		
		try playlist.setTracks(tracks)
		try updatePlaylistSet(withPlaylist: playlist, actionIsDelete: false)
		
		let newCount = playlistsSet.count
		ShortNotificationManager.instance.presentShortNotification(withMessage:"Saved \(oldCount < newCount ? "" : "changes to ")playlist: \(playlist.name)")
	}
	
	fileprivate func updatePlaylistSet(withPlaylist playlist:KyoozPlaylist, actionIsDelete:Bool) throws {
		func addOrRemove(_ remove:Bool) {
			if remove {
				playlistsSet.remove(playlist)
			} else {
				playlistsSet.add(playlist)
			}
		}
		addOrRemove(actionIsDelete)
		guard NSKeyedArchiver.archiveRootObject(playlistsSet, toFile: KyoozPlaylistManager.listDirectory) else {
			addOrRemove(!actionIsDelete)
			throw DataPersistenceError(errorDescription: "Failed update playlist master file for playlist \(playlist.name)")
		}
		
		Playlists.setMostRecentlyModified(playlist: playlist)
        DispatchQueue.main.asyncAfter(deadline: KyoozUtils.getDispatchTimeForSeconds(1.0)) {
            NotificationCenter.default.post(Notification(name: KyoozPlaylistManager.PlaylistSetUpdate, object: self))
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
        let urlString = KyoozPlaylistManager.listDirectory
        Logger.debug("playlist url \(urlString)")
        
        guard let object = NSKeyedUnarchiver.unarchiveObject(withFile: urlString) else {
            Logger.debug("couldnt find playlist set in list directory")
			guard NSKeyedArchiver.archiveRootObject(playlistsSet, toFile: urlString) else {
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
    
    func sourceDataForIndex(_ indexPath: IndexPath) -> AudioEntitySourceData? {
        guard let playlist = playlistsSet.object(at: (indexPath as NSIndexPath).row) as? KyoozPlaylist else {
            return nil
        }
        return KyoozPlaylistSourceData(playlist: playlist)
    }
    
    func deleteEntitiesAtIndexPaths(_ indexPaths: [IndexPath]) throws {
		
        let sortedIndexPaths = indexPaths.sorted() { ($0 as NSIndexPath).row > ($1 as NSIndexPath).row }
        for indexPath in sortedIndexPaths {
            guard let playlist = playlistsSet.object(at: (indexPath as NSIndexPath).row) as? KyoozPlaylist else {
                return
            }
            try deletePlaylist(playlist)
        }
    }
    
    func insertEntities(_ entities: [AudioEntity], atIndexPath indexPathToInsert: IndexPath) throws -> Int {
        throw KyoozError(errorDescription: "unsupported implementation")
    }
    
    func moveEntity(fromIndexPath originalIndexPath: IndexPath, toIndexPath destinationIndexPath: IndexPath) throws {
        //reordering is not supported
    }
    
    subscript(i:IndexPath) -> AudioEntity {
        return playlistsSet.object(at: (i as NSIndexPath).row) as! KyoozPlaylist
    }
}

final class KyoozPlaylist : NSObject, NSSecureCoding {
	
	static let nameKey = "kyoozPlaylist.name"
	static let countKey = "kyoozPlaylist.count"
	
    static var supportsSecureCoding: Bool {
		return true
	}
	
	override var hash:Int {
		return name.hash
	}
	
	override var hashValue:Int {
		return name.hashValue
	}
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherPlaylist = object as? KyoozPlaylist else {
            return false
        }
        return otherPlaylist.hash == hash
    }
    
	
	let name:String
	fileprivate (set) var count:Int = 0
    
    fileprivate var _tracks:[AudioTrack]! {
        didSet {
            count = _tracks?.count ?? 0
        }
    }
    
    fileprivate lazy var playlistTracksFileName : String = KyoozUtils.libraryDirectory.appendingPathComponent(self.name).path
	
	init(name:String) {
		self.name = name
	}
	
	init?(coder aDecoder: NSCoder) {
        guard let persistedName = aDecoder.decodeObject(of: NSString.self, forKey: KyoozPlaylist.nameKey) as? String else {
			name = "Unknown"
			count = 0
			return
		}
		
		count = aDecoder.decodeInteger(forKey: KyoozPlaylist.countKey)
		name = persistedName
	}
	

	
	fileprivate func setTracks(_ tracks:[AudioTrack]?) throws {
		guard let newTracks = tracks else {
			try FileManager.default.removeItem(atPath: playlistTracksFileName)
			return
		}
		
		guard NSKeyedArchiver.archiveRootObject(newTracks as NSArray, toFile: playlistTracksFileName) else {
			throw DataPersistenceError(errorDescription: "Failed to save the tracks for playlist \(name)")
		}
        _tracks = tracks
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(name, forKey: KyoozPlaylist.nameKey)
		aCoder.encode(count, forKey: KyoozPlaylist.countKey)
	}
	
}

extension KyoozPlaylist : AudioTrackCollection {
    var representativeTrack:AudioTrack? {
        return tracks.first
    }
    
    func titleForGrouping(_ libraryGrouping:LibraryGrouping) -> String? {
        if libraryGrouping == LibraryGrouping.Playlists {
            return name
        }
        return tracks.first?.titleForGrouping(libraryGrouping)
    }
    
    func persistentIdForGrouping(_ libraryGrouping:LibraryGrouping) -> UInt64 {
        return tracks.first?.persistentIdForGrouping(libraryGrouping) ?? 0
    }
    
    var tracks:[AudioTrack] {
        if _tracks == nil {
            _tracks = NSKeyedUnarchiver.unarchiveObject(withFile: playlistTracksFileName) as? [AudioTrack] ?? [AudioTrack]()
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


