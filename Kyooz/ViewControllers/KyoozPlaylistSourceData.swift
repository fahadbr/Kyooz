//
//  KyoozPlaylistSourceData.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/14/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

final class KyoozPlaylistSourceData : MutableAudioEntitySourceData {
	
	var parentGroup: LibraryGrouping? {
		return LibraryGrouping.Playlists
	}
	
	var parentCollection: AudioTrackCollection? {
		return playlist
	}
    
    var sections:[SectionDescription] {
        return [SectionDTO(name: playlist.name, count: playlist.count)]
    }
    var entities:[AudioEntity] {
        return playlist.tracks
    }
    
    var libraryGrouping:LibraryGrouping = LibraryGrouping.Songs
    
    let playlist:KyoozPlaylist
    
    init(playlist:KyoozPlaylist) {
        self.playlist = playlist
    }
    
    func reloadSourceData() {
        
    }
    
    func deleteEntitiesAtIndexPaths(indexPaths: [NSIndexPath]) throws {
        var tracks = playlist.tracks
        let sortedIndexPaths = indexPaths.sort() { $0.row > $1.row }
        for indexPath in sortedIndexPaths {
            guard indexPath.row < tracks.count else {
                throw KyoozError(errorDescription:"Cannot delete track \(indexPath.row + 1) because there are only \(tracks.count) tracks in the playlist")
            }
            
            tracks.removeAtIndex(indexPath.row)
        }
		try KyoozPlaylistManager.instance.update(playlist:playlist, withTracks: tracks)
    }
    
    func moveEntity(fromIndexPath originalIndexPath:NSIndexPath, toIndexPath destinationIndexPath:NSIndexPath) throws {
        var tracks = playlist.tracks
        guard originalIndexPath.row < tracks.count && destinationIndexPath.row < tracks.count else {
            throw KyoozError(errorDescription: "Source or Destination Position is not within the Playlist count")
        }
        
        let temp = tracks.removeAtIndex(originalIndexPath.row)
        tracks.insert(temp, atIndex: destinationIndexPath.row)
        try KyoozPlaylistManager.instance.update(playlist:playlist, withTracks: tracks)
    }
    
    func insertEntities(entities: [AudioEntity], atIndexPath indexPathToInsert: NSIndexPath) throws -> Int {
        guard indexPathToInsert.row <= playlist.count else {
            throw KyoozError(errorDescription: "IndexPath to insert is not within the Playlist count")
        }
        
        guard let audioTracks = (entities as? [AudioTrack]) ?? (entities as? [AudioTrackCollection])?.flatMap({ return $0.tracks })  else {
            throw KyoozError(errorDescription: "entities passed in to insert are not instances of AudioTrack or AudioTrackCollection")
        }
        
        var tracks = playlist.tracks
        tracks.insertContentsOf(audioTracks, at: indexPathToInsert.row)
        try KyoozPlaylistManager.instance.update(playlist:playlist, withTracks: tracks)
        return entities.count
    }
}
