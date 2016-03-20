//
//  AudioQueuePlayerSourceData.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/14/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

final class AudioQueuePlayerSourceData : MutableAudioEntitySourceData {
    
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
    
    func deleteEntitiesAtIndexPaths(indexPaths:[NSIndexPath]) throws {
        guard !indexPaths.isEmpty else { return }
        audioQueuePlayer.deleteItemsAtIndices(indexPaths.map({ $0.row }))
    }
    
    func moveEntity(fromIndexPath originalIndexPath:NSIndexPath, toIndexPath destinationIndexPath:NSIndexPath) throws {
        audioQueuePlayer.moveMediaItem(fromIndexPath: originalIndexPath.row, toIndexPath: destinationIndexPath.row)
    }
    
    func insertEntities(entities: [AudioEntity], atIndexPath indexPathToInsert: NSIndexPath) throws -> Int {
        guard let audioTracks = (entities as? [AudioTrack]) ?? (entities as? [AudioTrackCollection])?.flatMap({ return $0.tracks })  else {
            throw KyoozError(errorDescription: "entities passed in to insert are not instances of AudioTrack or AudioTrackCollection")
        }
        
        return audioQueuePlayer.insertItemsAtIndex(audioTracks, index: indexPathToInsert.row)
    }
}