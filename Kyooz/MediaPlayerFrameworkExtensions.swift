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
    override public func valueForUndefinedKey(key: String) -> AnyObject? {
        return self.representativeItem?.valueForProperty(key)
    }
    
    func titleForGrouping(libraryGrouping: LibraryGrouping) -> String? {
        let titleProperty = MPMediaItem.titlePropertyForGroupingType(libraryGrouping.groupingType)
        guard let representativeItem = self.representativeItem else {
            Logger.error("Could not get representative item for collection \(self.description)")
            return nil
        }
        return representativeItem.valueForProperty(titleProperty) as? String

    }
    
    func persistentIdForGrouping(libraryGrouping: LibraryGrouping) -> UInt64 {
        let idProperty = MPMediaItem.persistentIDPropertyForGroupingType(libraryGrouping.groupingType)
        return ((self.representativeItem)?.valueForProperty(idProperty) as? NSNumber)?.unsignedLongLongValue ?? 0
    }
    
    
    func artworkImage(forSize size:CGSize) -> UIImage? {
        return representativeTrack?.artworkImage(forSize: size)
    }
    
}

extension MPMediaPlaylist {
    
    override func titleForGrouping(libraryGrouping: LibraryGrouping) -> String? {
        if libraryGrouping !== LibraryGrouping.Playlists {
            return super.titleForGrouping(libraryGrouping)
        }
        return name
    }
    
    override func persistentIdForGrouping(libraryGrouping: LibraryGrouping) -> UInt64 {
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
    var isCloudTrack:Bool { return cloudItem }
    var hasArtwork:Bool { return artwork != nil }
    
    var releaseYear:String? {
        if let releaseDate = valueForKey("year") as? NSNumber where releaseDate.integerValue != 0 {
            return "\(releaseDate)"
        }
        return nil
    }
    
    func titleForGrouping(libraryGrouping: LibraryGrouping) -> String? {
        let titleProperty = MPMediaItem.titlePropertyForGroupingType(libraryGrouping.groupingType)
        return self.valueForProperty(titleProperty) as? String
    }
    
    func persistentIdForGrouping(libraryGrouping: LibraryGrouping) -> UInt64 {
        let idProperty = MPMediaItem.persistentIDPropertyForGroupingType(libraryGrouping.groupingType)
        return (self.valueForProperty(idProperty) as? NSNumber)?.unsignedLongLongValue ?? 0
    }
    
    var count:Int {
        return 1
    }
    
    var representativeTrack:AudioTrack? {
        return self
    }
	
	func artworkImage(forSize size: CGSize) -> UIImage? {
		return artwork?.imageWithSize(size)
	}

}

public func ==(lhs:MPMediaItem, rhs:MPMediaItem) -> Bool {
    return lhs.persistentID == rhs.persistentID
}

extension MPMediaQuery {
    static func albumArtistsQuery() -> MPMediaQuery {
        let query = MPMediaQuery.songsQuery()
        query.groupingType = MPMediaGrouping.AlbumArtist
        return query
    }
    
    
    func shouldQueryCloudItems(shouldQueryCloudItems:Bool) -> MPMediaQuery {
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
