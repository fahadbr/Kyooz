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
    var tracks:[AudioTrack] { get }
	
    var libraryGrouping:LibraryGrouping { get }
	
    func reloadSourceData()
    func flattenedIndex(_ indexPath:IndexPath) -> Int
    func getTracksAtIndex(_ indexPath:IndexPath) -> [AudioTrack]
    func sourceDataForIndex(_ indexPath:IndexPath) -> AudioEntitySourceData?
    
    subscript(i:IndexPath) -> AudioEntity { get }
}

protocol GroupMutableAudioEntitySourceData : AudioEntitySourceData {
	var libraryGrouping:LibraryGrouping { get set }
}

protocol MutableAudioEntitySourceData : AudioEntitySourceData {
    
    func deleteEntitiesAtIndexPaths(_ indexPaths:[IndexPath]) throws
    
    func moveEntity(fromIndexPath originalIndexPath:IndexPath, toIndexPath destinationIndexPath:IndexPath) throws
    
    func insertEntities(_ entities:[AudioEntity], atIndexPath indexPathToInsert:IndexPath) throws -> Int
}

extension AudioEntitySourceData {
    
    var sectionNamesCanBeUsedAsIndexTitles:Bool {
        return false
    }
    
    var tracks:[AudioTrack] {
        if let allTracks = entities as? [AudioTrack] {
            return allTracks
        } else if let collections = entities as? [AudioTrackCollection] {
            return collections.flatMap() { return $0.tracks }
        }
        Logger.error("couldn't get all tracks from entities of source data with type \(self.dynamicType)")
        return []
    }
    
    func getTracksAtIndex(_ indexPath:IndexPath) -> [AudioTrack] {
        
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
    
    func flattenedIndex(_ indexPath:IndexPath) -> Int {
        return (indexPath as NSIndexPath).row
    }
    
    func sourceDataForIndex(_ indexPath:IndexPath) -> AudioEntitySourceData? {
        return nil
    }
    
    subscript(i:IndexPath) -> AudioEntity {
        return entities[flattenedIndex(i)]
    }
}

