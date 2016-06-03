//
//  AudioEntitySourceData.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

protocol AudioEntitySourceData : class {
	
	var parentGroup:LibraryGrouping? { get }
	var parentCollection:AudioTrackCollection? { get }
	var sectionNamesCanBeUsedAsIndexTitles:Bool { get }
	var sections:[SectionDescription] { get }
    var entities:[AudioEntity] { get }
	
    var libraryGrouping:LibraryGrouping { get }
	
    func reloadSourceData()
    func flattenedIndex(indexPath:NSIndexPath) -> Int
    func getTracksAtIndex(indexPath:NSIndexPath) -> [AudioTrack]
    func sourceDataForIndex(indexPath:NSIndexPath) -> AudioEntitySourceData?
    
    subscript(i:NSIndexPath) -> AudioEntity { get }
}

protocol GroupMutableAudioEntitySourceData : AudioEntitySourceData {
	var libraryGrouping:LibraryGrouping { get set }
}

protocol MutableAudioEntitySourceData : AudioEntitySourceData {
    
    func deleteEntitiesAtIndexPaths(indexPaths:[NSIndexPath]) throws
    
    func moveEntity(fromIndexPath originalIndexPath:NSIndexPath, toIndexPath destinationIndexPath:NSIndexPath) throws
    
    func insertEntities(entities:[AudioEntity], atIndexPath indexPathToInsert:NSIndexPath) throws -> Int
}

extension AudioEntitySourceData {
    
    var sectionNamesCanBeUsedAsIndexTitles:Bool {
        return false
    }
    
    func getTracksAtIndex(indexPath:NSIndexPath) -> [AudioTrack] {
        
        if !entities.isEmpty {
            let entity = self[indexPath]
            if let collection = entity as? AudioTrackCollection {
                return collection.tracks
            } else if let track = entity as? AudioTrack {
                return [track]
            }
        }
        
        return [AudioTrack]()
    }
    
    func flattenedIndex(indexPath:NSIndexPath) -> Int {
        return indexPath.row
    }
    
    func sourceDataForIndex(indexPath:NSIndexPath) -> AudioEntitySourceData? {
        return nil
    }
    
    subscript(i:NSIndexPath) -> AudioEntity {
        return entities[flattenedIndex(i)]
    }
}

