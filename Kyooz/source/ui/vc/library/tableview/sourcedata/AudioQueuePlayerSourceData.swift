//
//  AudioQueuePlayerSourceData.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/14/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

final class AudioQueuePlayerSourceData : MutableAudioEntitySourceData {
	
	var parentGroup: LibraryGrouping? {
		return nil
	}
	
	var parentCollection: AudioTrackCollection? {
		return nil
	}
    
    var sectionNamesCanBeUsedAsIndexTitles:Bool {
        return false
    }
    
    var sections:[SectionDescription] {
        return [SectionDTO(name: "CURRENT QUEUE", count: entities.count)]
    }
    
    var entities:[AudioEntity] {
        return audioQueuePlayer.nowPlayingQueue
    }
    
    var libraryGrouping:LibraryGrouping {
        return LibraryGrouping.Songs
    }
    
    let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    func reloadSourceData() {    }
    
    func deleteEntitiesAtIndexPaths(_ indexPaths:[IndexPath]) throws {
        guard !indexPaths.isEmpty else { return }
        audioQueuePlayer.delete(at: indexPaths.map { ($0 as NSIndexPath).row })
    }
    
    func moveEntity(fromIndexPath originalIndexPath:IndexPath, toIndexPath destinationIndexPath:IndexPath) throws {
        audioQueuePlayer.move(from: (originalIndexPath as NSIndexPath).row, to: (destinationIndexPath as NSIndexPath).row)
    }
    
    func insertEntities(_ entities: [AudioEntity], atIndexPath indexPathToInsert: IndexPath) throws -> Int {
        guard let audioTracks = (entities as? [AudioTrack]) ?? (entities as? [AudioTrackCollection])?.flatMap({ return $0.tracks })  else {
            throw KyoozError(errorDescription: "entities passed in to insert are not instances of AudioTrack or AudioTrackCollection")
        }
        return audioQueuePlayer.insert(tracks: audioTracks, at: (indexPathToInsert as NSIndexPath).row)
    }
}
