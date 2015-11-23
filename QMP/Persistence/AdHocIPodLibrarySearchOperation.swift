//
//  BruteForceSearchOperation.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/19/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

class AdHocIPodLibrarySearchOperation : AbstractSearchOperation<MPMediaEntity> {
    

    private let group:LibraryGrouping
    private let searchString:String
    private let searchPredicate:NSPredicate
    
    private (set) var finalResults:[MPMediaEntity]!
    private (set) var fullSearchOperation:FullIpodLibrarySearchOperation!
    
    init(group:LibraryGrouping, searchString:String, searchPredicate:NSPredicate) {
        self.group = group
        self.searchString = searchString
        self.searchPredicate = searchPredicate
    }
        
    override func main() {
        if cancelled {
            return
        }
        let isItemQuery:Bool = group == LibraryGrouping.Songs
        guard let entities:[MPMediaEntity] = isItemQuery ? group.baseQuery.items : group.baseQuery.collections else {
            return
        }
        guard let sections = isItemQuery ? group.baseQuery.itemSections : group.baseQuery.collectionSections else {
            return
        }
        
        var startIndex = 0
        var endIndex = !entities.isEmpty ? entities.count - 1 : 0
        if let section = sections.filter( { $0.title.normalizedString == searchString[0] }).first {
            startIndex = section.range.location
            endIndex = startIndex + section.range.length
        }
        
        finalResults = [MPMediaEntity]()
        let title = MPMediaItem.titlePropertyForGroupingType(group.groupingType)
        for i in startIndex...endIndex {
            let value = entities[i]
            guard let primaryKey = value.titleForGrouping(group.groupingType)?.normalizedString else {
                continue
            }
            if searchPredicate.evaluateWithObject(SearchIndexEntry(object: value, primaryKeyValue: (title,primaryKey))) {
                finalResults.append(value)
            }
            if cancelled {
                return
            }
        }
        
        if !cancelled {
            fullSearchOperation = FullIpodLibrarySearchOperation(group: group, searchString: searchString, searchPredicate: searchPredicate, primaryResults: finalResults, fullList: entities)

            inThreadCompletionBlock?(finalResults)
            fullSearchOperation.inThreadCompletionBlock = inThreadCompletionBlock
            NSOperationQueue.currentQueue()?.addOperation(fullSearchOperation)
        }
    }
    
}

