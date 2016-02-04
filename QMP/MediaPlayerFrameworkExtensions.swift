//
//  MediaPlayerExtensions.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import MediaPlayer

extension MPMediaEntity {
    
    
    var representativeItem:AudioTrack? {
        if let collection = self as? MPMediaItemCollection {
            return collection.representativeItem
        } else {
            return self as? MPMediaItem
        }
    }
    
    func titleForGrouping(libraryGrouping:LibraryGrouping) -> String? {
        let grouping = libraryGrouping.groupingType
        if let playlist = self as? MPMediaPlaylist where grouping == .Playlist {
            return playlist.name
        }
        if let collection = self as? MPMediaItemCollection {
            let titleProperty = MPMediaItem.titlePropertyForGroupingType(grouping)
            guard let representativeItem = collection.representativeItem else {
                Logger.error("Could not get representative item for collection \(self.description)")
                return nil
            }
            return representativeItem.valueForProperty(titleProperty) as? String
        } else if let mediaItem = self as? MPMediaItem {
            let titleProperty = MPMediaItem.titlePropertyForGroupingType(grouping)
            return mediaItem.valueForProperty(titleProperty) as? String
        }
        
        return nil
    }
    
    func persistentIdForGrouping(libraryGrouping: LibraryGrouping) -> UInt64 {
        let idProperty = MPMediaItem.persistentIDPropertyForGroupingType(libraryGrouping.groupingType)
        return ((self.representativeItem as? MPMediaItem)?.valueForKey(idProperty) as? NSNumber)?.unsignedLongLongValue ?? 0
    }
    
    var count:Int {
        if let collection = self as? MPMediaItemCollection {
            return collection.count
        } else {
            return 1
        }
    }
    
}


extension MPMediaItemCollection : AudioTrackCollection {
    
    //overriding this so that collections can be searched by their underlying track properties
    override public func valueForUndefinedKey(key: String) -> AnyObject? {
        return self.representativeItem?.valueForProperty(key)
    }
    
    override func titleForGrouping(libraryGrouping: LibraryGrouping) -> String? {
        let titleProperty = MPMediaItem.titlePropertyForGroupingType(libraryGrouping.groupingType)
        guard let representativeItem = self.representativeItem else {
            Logger.error("Could not get representative item for collection \(self.description)")
            return nil
        }
        return representativeItem.valueForProperty(titleProperty) as? String

    }
    
    var representativeTrack:AudioTrack? {
        return representativeItem
    }
    
    override func persistentIdForGrouping(libraryGrouping: LibraryGrouping) -> UInt64 {
        let idProperty = MPMediaItem.persistentIDPropertyForGroupingType(libraryGrouping.groupingType)
        return ((self.representativeItem)?.valueForProperty(idProperty) as? NSNumber)?.unsignedLongLongValue ?? 0
    }
    
    var tracks:[AudioTrack] { return self.items }
    
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
}

extension MPMediaItem : AudioTrack {
    
    var trackTitle:String { return title ?? "Error: track not found" }
    var id:UInt64 { return persistentID }
    var albumArtistId:UInt64 { return albumArtistPersistentID }
    var albumId:UInt64 { return albumPersistentID }
    var audioTrackSource:AudioTrackSource { return AudioTrackSource.iPodLibrary }
    var isCloudTrack:Bool { return cloudItem }
    
    override func titleForGrouping(libraryGrouping: LibraryGrouping) -> String? {
        let titleProperty = MPMediaItem.titlePropertyForGroupingType(libraryGrouping.groupingType)
        return self.valueForProperty(titleProperty) as? String
    }
    
    override func persistentIdForGrouping(libraryGrouping: LibraryGrouping) -> UInt64 {
        let idProperty = MPMediaItem.persistentIDPropertyForGroupingType(libraryGrouping.groupingType)
        return (self.valueForProperty(idProperty) as? NSNumber)?.unsignedLongLongValue ?? 0
    }
    
    override var count:Int {
        return 1
    }
    
    var representativeTrack:AudioTrack? {
        return self
    }

}

public func ==(lhs:MPMediaItem, rhs:MPMediaItem) -> Bool {
    return lhs.persistentID == rhs.persistentID
}

extension MPMediaQuery {
    static func albumArtistsQuery() -> MPMediaQuery {
        let query = MPMediaQuery()
        query.groupingType = MPMediaGrouping.AlbumArtist
        return query
    }
    
    static func audioQueryForGrouping(grouping:MPMediaGrouping, isCompilation:Bool = false) -> MPMediaQuery {
        let query = MPMediaQuery()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: MPMediaType.AnyAudio.rawValue, forProperty: MPMediaItemPropertyMediaType))
        query.groupingType = grouping
        if isCompilation {
            query.addFilterPredicate(MPMediaPropertyPredicate(value: true, forProperty: MPMediaItemPropertyIsCompilation))
        }
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
