//
//  FullIpodLibrarySearchOperation.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/20/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

class FullIpodLibrarySearchOperation : AbstractSearchOperation<MPMediaEntity> {
    
    private let group:LibraryGrouping
    private let searchString:String
    private let searchPredicate:NSPredicate
    private let primaryResults:[MPMediaEntity]
    private let fullList:[MPMediaEntity]
    
    private (set) var finalResults:[MPMediaEntity]!
    
    init(group:LibraryGrouping, searchString:String, searchPredicate:NSPredicate, primaryResults:[MPMediaEntity], fullList:[MPMediaEntity]) {
        self.group = group
        self.searchString = searchString
        self.searchPredicate = searchPredicate
        self.primaryResults = primaryResults
        self.fullList = fullList
    }
    
    
    override func main() {
        if cancelled {
            return
        }
        let title = MPMediaItem.titlePropertyForGroupingType(group.groupingType)
        var secondaryResults = [MPMediaEntity]()
        for entity in fullList {
            guard let primaryKey = entity.titleForGrouping(group.groupingType)?.normalizedString else {
                continue
            }
            if searchPredicate.evaluateWithObject(SearchIndexEntry(object: entity, primaryKeyValue: (title,primaryKey))) {
                secondaryResults.append(entity)
            }
            if cancelled {
                return
            }
        }
        
        if(secondaryResults.isEmpty) { return }
        let primarySet = Set<MPMediaEntity>(primaryResults)
        let resultsSet = Set<MPMediaEntity>(secondaryResults)
        let differenceSet = resultsSet.subtract(primarySet)
        
        if !cancelled {
            finalResults = primaryResults
            finalResults.appendContentsOf(differenceSet)
            
            inThreadCompletionBlock?(finalResults)
        }
    }
}