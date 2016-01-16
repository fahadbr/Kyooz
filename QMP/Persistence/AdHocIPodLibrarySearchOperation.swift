//
//  BruteForceSearchOperation.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/19/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

final class AdHocIPodLibrarySearchOperation : AbstractResultOperation<[MPMediaEntity]> {
    

    private let group:LibraryGrouping
    private let searchString:String
    private let searchPredicate:NSPredicate
    
    init(group:LibraryGrouping, searchString:String, searchPredicate:NSPredicate) {
        self.group = group
        self.searchString = searchString
        self.searchPredicate = searchPredicate
    }
        
    override func main() {
        if cancelled { return }
        
        let isItemQuery:Bool = group == LibraryGrouping.Songs
        guard let entities:[MPMediaEntity] = isItemQuery ? group.baseQuery.items : group.baseQuery.collections else {
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
        
        var finalResults = [MPMediaEntity]()
        let title = MPMediaItem.titlePropertyForGroupingType(group.groupingType)
        for i in startIndex...endIndex {
            let value = entities[i]
            guard let primaryKey = value.titleForGrouping(group.groupingType)?.normalizedString else {
                continue
            }
            if searchPredicate.evaluateWithObject(SearchIndexEntry(object: value, primaryKeyValue: (title,primaryKey))) {
                finalResults.append(value)
            }
            if cancelled { return }
        }
        
        if cancelled { return }
        
        inThreadCompletionBlock?(finalResults)
        
        if cancelled { return }

        //now do a full library search
        var secondaryResults = [MPMediaEntity]()
        for entity in entities {
            guard let primaryKey = entity.titleForGrouping(group.groupingType)?.normalizedString else {
                continue
            }
            if searchPredicate.evaluateWithObject(SearchIndexEntry(object: entity, primaryKeyValue: (title,primaryKey))) {
                secondaryResults.append(entity)
            }
            
            if cancelled { return }
        }
        
        if(secondaryResults.isEmpty) { return }
        
        let primarySet = Set<MPMediaEntity>(finalResults)
        let resultsSet = Set<MPMediaEntity>(secondaryResults)
        let differenceSet = resultsSet.subtract(primarySet)
    
        finalResults.appendContentsOf(differenceSet)
        
        if cancelled { return }
        
        inThreadCompletionBlock?(finalResults)

    }
    
}

