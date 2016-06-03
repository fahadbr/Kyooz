//
//  MediaQuerySourceData.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/14/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import MediaPlayer

final class MediaQuerySourceData : GroupMutableAudioEntitySourceData {
	
    
    var sectionNamesCanBeUsedAsIndexTitles:Bool {
        return _sections != nil
    }
    
    var sections:[SectionDescription] {
        return _sections ?? singleSectionArray
    }
    
    var entities:[AudioEntity] = [AudioEntity]() {
        didSet {
            singleSectionArray = [SectionDTO(name: singleSectionName ?? libraryGrouping.name, count: entities.count)]
        }
    }
    
    var libraryGrouping:LibraryGrouping {
        didSet {
            filterQuery.groupingType = libraryGrouping.groupingType
        }
    }
	
	private (set) var parentGroup: LibraryGrouping?
	private (set) var parentCollection: AudioTrackCollection?
    
    private var _sections:[MPMediaQuerySection]?
    private var singleSectionArray:[SectionDescription] = [SectionDTO(name: "", count: 0)]
    
    private let singleSectionName:String?
    private (set) var filterQuery:MPMediaQuery
    
    convenience init(filterQuery:MPMediaQuery, libraryGrouping:LibraryGrouping) {
        self.init(filterQuery:filterQuery, libraryGrouping:libraryGrouping, singleSectionName:nil)
    }
    
    init(filterQuery:MPMediaQuery, libraryGrouping:LibraryGrouping, singleSectionName:String?) {
        self.filterQuery = filterQuery
        self.libraryGrouping = libraryGrouping
        self.singleSectionName = singleSectionName
        reloadSourceData()
    }
    
    convenience init?(filterEntity:AudioEntity, parentLibraryGroup:LibraryGrouping, baseQuery:MPMediaQuery?) {
        guard let nextLibraryGroup = parentLibraryGroup.nextGroupLevel else {
            return nil
        }
		
        let propertyName = MPMediaItem.persistentIDPropertyForGroupingType(parentLibraryGroup.groupingType)
        let propertyValue = NSNumber(unsignedLongLong: filterEntity.persistentIdForGrouping(parentLibraryGroup))
        
        let filterQuery = MPMediaQuery(filterPredicates: baseQuery?.filterPredicates ?? parentLibraryGroup.baseQuery.filterPredicates)
        filterQuery.addFilterPredicate(MPMediaPropertyPredicate(value: propertyValue, forProperty: propertyName))
        filterQuery.groupingType = nextLibraryGroup.groupingType
        
        self.init(filterQuery:filterQuery, libraryGrouping:nextLibraryGroup, singleSectionName:nil)
		self.parentGroup = parentLibraryGroup
		self.parentCollection = filterEntity as? AudioTrackCollection
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