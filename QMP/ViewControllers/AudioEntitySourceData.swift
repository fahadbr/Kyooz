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
    
    var numberOfSections:Int { get }
    var sectionNames:[String]? { get }
    
    var entities:[AudioEntity] { get }
    var libraryGrouping:LibraryGrouping { get set }
    
    func numberOfItemsInSection(section:Int) -> Int
    func reloadSourceData()

    subscript(i:NSIndexPath) -> AudioEntity { get }
    
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
	let numberOfSections:Int = 1
	var sectionNames:[String]?
	
	var entities:[AudioEntity]
	var libraryGrouping:LibraryGrouping = LibraryGrouping.Songs
	
	let playlist:KyoozPlaylist
	
	init(playlist:KyoozPlaylist) {
		sectionNames = [playlist.name]
		entities = playlist.getTracks()
		self.playlist = playlist
	}
	
	func numberOfItemsInSection(section:Int) -> Int {
		return entities.count
	}
	func reloadSourceData() {
		entities = playlist.getTracks()
	}
	
	subscript(i:NSIndexPath) -> AudioEntity {
		return entities[i.row]
	}
}

final class MediaQuerySourceData :  AudioEntitySourceData {

    var entities:[AudioEntity] = [AudioEntity]()
    var libraryGrouping:LibraryGrouping {
        didSet {
            filterQuery.groupingType = libraryGrouping.groupingType
        }
    }
    
    var numberOfSections:Int {
        return sections?.count ?? 1
    }
    
    var sectionNames:[String]? {
        if _sectionNames == nil {
            _sectionNames = sections?.map() { $0.title }
        }
        return _sectionNames
    }
    
    private var _sectionNames:[String]?
    
	private var sections:[MPMediaQuerySection]? {
		didSet {
			_sectionNames = nil
		}
	}
    private (set) var filterQuery:MPMediaQuery
    
    init(filterQuery:MPMediaQuery, libraryGrouping:LibraryGrouping) {
        self.filterQuery = filterQuery
        self.libraryGrouping = libraryGrouping
        reloadSourceData()
    }
    
    func numberOfItemsInSection(section: Int) -> Int {
        return sections?[section].range.length ?? entities.count
    }
    
    func reloadSourceData() {
        let isSongGrouping = libraryGrouping == LibraryGrouping.Songs
        entities = (isSongGrouping ? filterQuery.items : filterQuery.collections) ?? [AudioEntity]()
        
        if entities.count < 15 {
            self.sections = nil
            return
        }
        
        let sections = isSongGrouping ? filterQuery.itemSections : filterQuery.collectionSections
        if sections != nil && sections!.count > 1 {
            self.sections = sections
        }
    }
    
    subscript(i:NSIndexPath) -> AudioEntity {
        return entities[getAbsoluteIndex(i)]
    }
    
    private func getAbsoluteIndex(indexPath: NSIndexPath) -> Int{
        guard let sections = self.sections else {
            return indexPath.row
        }
        
        let offset =  sections[indexPath.section].range.location
        let index = indexPath.row
        let absoluteIndex = offset + index
        
        return absoluteIndex
    }
    
}