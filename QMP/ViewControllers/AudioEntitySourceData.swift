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

    subscript(i:NSIndexPath) -> AudioEntity { get }
    
}

protocol SectionDescription {
	var name:String { get }
	var count:Int { get }
}

struct SectionDTO : SectionDescription {
	let name:String
	let count:Int
}

extension AudioEntitySourceData {
    
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
    
}

final class KyoozPlaylistSourceData : AudioEntitySourceData {
	
	var sectionNamesCanBeUsedAsIndexTitles:Bool {
		return false
	}
	
	var sections:[SectionDescription]
	var entities:[AudioEntity]
	var libraryGrouping:LibraryGrouping = LibraryGrouping.Songs
	
	let playlist:KyoozPlaylist
	
	init(playlist:KyoozPlaylist) {
		sections = [SectionDTO(name: playlist.name, count: playlist.count)]
		entities = playlist.getTracks()
		self.playlist = playlist
	}

	func reloadSourceData() {
		entities = playlist.getTracks()
	}
	
	subscript(i:NSIndexPath) -> AudioEntity {
		return entities[i.row]
	}
}

final class MediaQuerySourceData : AudioEntitySourceData {

	var sectionNamesCanBeUsedAsIndexTitles:Bool {
		return true
	}
	
	var sections:[SectionDescription] {
		return _sections ?? singleSectionArray
	}
	
	var entities:[AudioEntity] = [AudioEntity]() {
		didSet {
			singleSectionArray = [SectionDTO(name: "", count: entities.count)]
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
    
    subscript(i:NSIndexPath) -> AudioEntity {
        return entities[getAbsoluteIndex(i)]
    }
    
    private func getAbsoluteIndex(indexPath: NSIndexPath) -> Int{
        guard let sections = self._sections else {
            return indexPath.row
        }
        
        let offset =  sections[indexPath.section].range.location
        let index = indexPath.row
        let absoluteIndex = offset + index
        
        return absoluteIndex
    }
    
}