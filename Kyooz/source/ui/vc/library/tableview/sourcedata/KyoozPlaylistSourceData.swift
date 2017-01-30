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
    
    func deleteEntitiesAtIndexPaths(_ indexPaths: [IndexPath]) throws {
        var tracks = playlist.tracks
        let sortedIndexPaths = indexPaths.sorted() { ($0 as NSIndexPath).row > ($1 as NSIndexPath).row }
        for indexPath in sortedIndexPaths {
            guard (indexPath as NSIndexPath).row < tracks.count else {
                throw KyoozError(errorDescription:"Cannot delete track \((indexPath as NSIndexPath).row + 1) because there are only \(tracks.count) tracks in the playlist")
            }
            
            tracks.remove(at: (indexPath as NSIndexPath).row)
        }
		try KyoozPlaylistManager.instance.update(playlist:playlist, withTracks: tracks)
    }
    
    func moveEntity(fromIndexPath originalIndexPath:IndexPath, toIndexPath destinationIndexPath:IndexPath) throws {
        var tracks = playlist.tracks
        guard (originalIndexPath as NSIndexPath).row < tracks.count && (destinationIndexPath as NSIndexPath).row < tracks.count else {
            throw KyoozError(errorDescription: "Source or Destination Position is not within the Playlist count")
        }
        
        let temp = tracks.remove(at: (originalIndexPath as NSIndexPath).row)
        tracks.insert(temp, at: (destinationIndexPath as NSIndexPath).row)
        try KyoozPlaylistManager.instance.update(playlist:playlist, withTracks: tracks)
    }
    
    func insertEntities(_ entities: [AudioEntity], atIndexPath indexPathToInsert: IndexPath) throws -> Int {
        guard (indexPathToInsert as NSIndexPath).row <= playlist.count else {
            throw KyoozError(errorDescription: "IndexPath to insert is not within the Playlist count")
        }
        
        guard let audioTracks = (entities as? [AudioTrack]) ?? (entities as? [AudioTrackCollection])?.flatMap({ return $0.tracks })  else {
            throw KyoozError(errorDescription: "entities passed in to insert are not instances of AudioTrack or AudioTrackCollection")
        }
        
        var tracks = playlist.tracks
        tracks.insert(contentsOf: audioTracks, at: (indexPathToInsert as NSIndexPath).row)
        try KyoozPlaylistManager.instance.update(playlist:playlist, withTracks: tracks)
        return entities.count
    }
}
