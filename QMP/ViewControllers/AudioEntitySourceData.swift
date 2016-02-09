//
//  AudioEntityDataSource.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

protocol AudioEntitySourceData {
	
	var sectionNamesCanBeUsedAsIndexTitles:Bool { get }
	var sections:[SectionDescription] { get }
    var entities:[AudioEntity] { get }
	
    var libraryGrouping:LibraryGrouping { get set }
	
    func reloadSourceData()
    func flattenedIndex(indexPath:NSIndexPath) -> Int
    func getTracksAtIndex(indexPath:NSIndexPath) -> [AudioTrack]
    func sourceDataForIndex(indexPath:NSIndexPath) -> AudioEntitySourceData?
    
    subscript(i:NSIndexPath) -> AudioEntity { get }
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

@objc protocol SectionDescription {
	var name:String { get }
	var count:Int { get }
}

class SectionDTO : SectionDescription {
	@objc let name:String
	@objc let count:Int
    init(name:String, count:Int) {
        self.name = name
        self.count = count
    }
}



final class KyoozPlaylistSourceData : AudioEntitySourceData {
	
    var sections:[SectionDescription] {
        return [SectionDTO(name: playlist.name, count: playlist.count)]
    }
	var entities:[AudioEntity]
	var libraryGrouping:LibraryGrouping = LibraryGrouping.Songs
	
	let playlist:KyoozPlaylist
	
	init(playlist:KyoozPlaylist) {
		entities = playlist.tracks
		self.playlist = playlist
	}

	func reloadSourceData() {
		entities = playlist.tracks
	}
}

final class MediaQuerySourceData : AudioEntitySourceData {

	var sectionNamesCanBeUsedAsIndexTitles:Bool {
		return _sections != nil
	}
	
	var sections:[SectionDescription] {
		return _sections ?? singleSectionArray
	}
	
	var entities:[AudioEntity] = [AudioEntity]() {
		didSet {
			singleSectionArray = [SectionDTO(name: libraryGrouping.name, count: entities.count)]
		}
	}
	
    var libraryGrouping:LibraryGrouping {
        didSet {
            filterQuery.groupingType = libraryGrouping.groupingType
        }
    }
	
	private var _sections:[MPMediaQuerySection]?
	private var singleSectionArray:[SectionDescription] = [SectionDTO(name: "", count: 0)]
    private (set) var filterQuery:MPMediaQuery
    
    init(filterQuery:MPMediaQuery, libraryGrouping:LibraryGrouping) {
        self.filterQuery = filterQuery
        self.libraryGrouping = libraryGrouping
        reloadSourceData()
    }
    
    init?(filterEntity:AudioEntity, parentLibraryGroup:LibraryGrouping, baseQuery:MPMediaQuery?) {
        guard let nextLibraryGroup = parentLibraryGroup.nextGroupLevel else {
            self.filterQuery = MPMediaQuery()
            self.libraryGrouping = parentLibraryGroup
            return nil
        }
        
        let propertyName = MPMediaItem.persistentIDPropertyForGroupingType(parentLibraryGroup.groupingType)
        let propertyValue = NSNumber(unsignedLongLong: filterEntity.persistentIdForGrouping(parentLibraryGroup))
        
        let filterQuery = MPMediaQuery(filterPredicates: baseQuery?.filterPredicates ?? parentLibraryGroup.baseQuery.filterPredicates)
        filterQuery.addFilterPredicate(MPMediaPropertyPredicate(value: propertyValue, forProperty: propertyName))
        filterQuery.groupingType = nextLibraryGroup.groupingType
        
        self.filterQuery = filterQuery
        self.libraryGrouping = nextLibraryGroup
        reloadSourceData()
    }
    
    func reloadSourceData() {
        let isSongGrouping = libraryGrouping == LibraryGrouping.Songs
        entities = (isSongGrouping ? filterQuery.items : filterQuery.collections) ?? [AudioEntity]()
        
        if entities.count < 15 {
            self._sections = nil
            return
        }
        
        let sections = isSongGrouping ? filterQuery.itemSections : filterQuery.collectionSections
        if sections != nil && sections!.count > 1 {
            self._sections = sections
        }
		
    }
    
    func sourceDataForIndex(indexPath: NSIndexPath) -> AudioEntitySourceData? {
        let entity = self[indexPath]
        
        return MediaQuerySourceData(filterEntity: entity, parentLibraryGroup: libraryGrouping, baseQuery: filterQuery)
    }
    
    func flattenedIndex(indexPath: NSIndexPath) -> Int {
        guard let sections = self._sections else {
            return indexPath.row
        }
        
        let offset =  sections[indexPath.section].range.location
        let index = indexPath.row
        let absoluteIndex = offset + index
        
        return absoluteIndex
    }
    
    
}