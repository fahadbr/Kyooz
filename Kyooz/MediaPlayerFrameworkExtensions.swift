//
//  MediaPlayerExtensions.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import MediaPlayer



extension MPMediaItemCollection : AudioTrackCollection {
    
    var representativeTrack:AudioTrack? {
        return representativeItem
    }
    var tracks:[AudioTrack] { return self.items }
    
    //overriding this so that collections can be searched by their underlying track properties
    override public func value(forUndefinedKey key: String) -> AnyObject? {
        return self.representativeItem?.value(forProperty: key)
    }
    
    func titleForGrouping(_ libraryGrouping: LibraryGrouping) -> String? {
        let titleProperty = MPMediaItem.titleProperty(forGroupingType: libraryGrouping.groupingType)
        guard let representativeItem = self.representativeItem else {
            Logger.error("Could not get representative item for collection \(self.description)")
            return nil
        }
        return representativeItem.value(forProperty: titleProperty) as? String

    }
    
    func persistentIdForGrouping(_ libraryGrouping: LibraryGrouping) -> UInt64 {
        let idProperty = MPMediaItem.persistentIDProperty(forGroupingType: libraryGrouping.groupingType)
        return ((self.representativeItem)?.value(forProperty: idProperty) as? NSNumber)?.uint64Value ?? 0
    }
    
    
    func artworkImage(forSize size:CGSize) -> UIImage? {
        return representativeTrack?.artworkImage(forSize: size)
    }
    
}

extension MPMediaPlaylist {
    
    override func titleForGrouping(_ libraryGrouping: LibraryGrouping) -> String? {
        if libraryGrouping !== LibraryGrouping.Playlists {
            return super.titleForGrouping(libraryGrouping)
        }
        return name
    }
    
    override func persistentIdForGrouping(_ libraryGrouping: LibraryGrouping) -> UInt64 {
        if libraryGrouping !== LibraryGrouping.Playlists {
            return super.persistentIdForGrouping(libraryGrouping)
        }
        return persistentID
    }
    
    override func artworkImage(forSize size: CGSize) -> UIImage? {
        return ImageUtils.mergeArtwork(forTracks: tracks, usingSize: size)
    }
}

extension MPMediaItem : AudioTrack {
    
    var trackTitle:String { return title ?? "Error: track not found" }
    var id:UInt64 { return persistentID }
    var albumArtistId:UInt64 { return albumArtistPersistentID }
    var albumId:UInt64 { return albumPersistentID }
    var audioTrackSource:AudioTrackSource { return AudioTrackSource.iPodLibrary }
    var isCloudTrack:Bool { return isCloudItem }
    var hasArtwork:Bool { return artwork != nil }
    
    var releaseYear:String? {
        if let releaseDate = value(forKey: "year") as? NSNumber where releaseDate.intValue != 0 {
            return "\(releaseDate)"
        }
        return nil
    }
    
    func titleForGrouping(_ libraryGrouping: LibraryGrouping) -> String? {
        let titleProperty = MPMediaItem.titleProperty(forGroupingType: libraryGrouping.groupingType)
        return self.value(forProperty: titleProperty) as? String
    }
    
    func persistentIdForGrouping(_ libraryGrouping: LibraryGrouping) -> UInt64 {
        let idProperty = MPMediaItem.persistentIDProperty(forGroupingType: libraryGrouping.groupingType)
        return (self.value(forProperty: idProperty) as? NSNumber)?.uint64Value ?? 0
    }
    
    var count:Int {
        return 1
    }
    
    var representativeTrack:AudioTrack? {
        return self
    }
	
	func artworkImage(forSize size: CGSize) -> UIImage? {
		return artwork?.image(at: size)
	}

}

public func ==(lhs:MPMediaItem, rhs:MPMediaItem) -> Bool {
    return lhs.persistentID == rhs.persistentID
}

extension MPMediaQuery {
    static func albumArtistsQuery() -> MPMediaQuery {
        let query = MPMediaQuery.songs()
        query.groupingType = MPMediaGrouping.albumArtist
        return query
    }
    
    
    func shouldQueryCloudItems(_ shouldQueryCloudItems:Bool) -> MPMediaQuery {
        if(!shouldQueryCloudItems) {
            self.addFilterPredicate(MPMediaPropertyPredicate(value: shouldQueryCloudItems, forProperty: MPMediaItemPropertyIsCloudItem))
        }
        return self
    }
    
}

extension MPMediaQuerySection : SectionDescription {
	
	var name:String {
		return title
	}
	
	var count:Int {
		return range.length
	}
}
