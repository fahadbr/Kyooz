//
//  BruteForceSearchOperation.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/19/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

final class AdHocIPodLibrarySearchOperation : AbstractResultOperation<[AudioEntity]> {
    

    private let group:LibraryGrouping
    private let searchString:String
    private let searchPredicate:NSPredicate
    
    init(group:LibraryGrouping, searchString:String, searchPredicate:NSPredicate) {
        self.group = group
        self.searchString = searchString
        self.searchPredicate = searchPredicate
    }
        
    override func main() {
        if isCancelled { return }
        
        let isItemQuery:Bool = group == LibraryGrouping.Songs
        guard let entities:[AudioEntity] = isItemQuery ? group.baseQuery.items : group.baseQuery.collections else {
            return
        }
        
        var sections:[MPMediaQuerySection]? = nil
        if let resultSections = isItemQuery ? group.baseQuery.itemSections : group.baseQuery.collectionSections {
            if resultSections.count > 1 {
                sections = resultSections
            }
        }
        
        
        var startIndex = 0
        var endIndex = !entities.isEmpty ? entities.count - 1 : 0
        if let section = sections?.filter( { $0.title.normalizedString == searchString[0] }).first {
            startIndex = section.range.location
            endIndex = startIndex + section.range.length
        }
        
        var finalResults = [AudioEntity]()
        let title = MPMediaItem.titleProperty(forGroupingType: group.groupingType)
        for i in startIndex...endIndex {
            let value = entities[i]
            guard let primaryKey = value.titleForGrouping(group)?.normalizedString else {
                continue
            }
            if searchPredicate.evaluate(with: SearchIndexEntry(object: value, primaryKeyValue: (title,primaryKey))) {
                finalResults.append(value)
            }
            if isCancelled { return }
        }
        
        if isCancelled { return }
        
        inThreadCompletionBlock?(finalResults)
        
        if isCancelled { return }

        //now do a full library search
        var secondaryResults = [AudioEntity]()
        for entity in entities {
            guard let primaryKey = entity.titleForGrouping(group)?.normalizedString else {
                continue
            }
            if searchPredicate.evaluate(with: SearchIndexEntry(object: entity, primaryKeyValue: (title,primaryKey))) {
                secondaryResults.append(entity)
            }
            
            if isCancelled { return }
        }
        
        if(secondaryResults.isEmpty) { return }
		
		let primarySet = NSSet(array: finalResults)
		let resultsSet = NSMutableSet(array: secondaryResults)
		resultsSet.minus(primarySet as Set<NSObject>)
		
		guard let differences = resultsSet.allObjects as? [AudioEntity] else {
			return
		}
		
        finalResults.append(contentsOf: differences)
        
        if isCancelled { return }
        
        inThreadCompletionBlock?(finalResults)

    }
    
}

