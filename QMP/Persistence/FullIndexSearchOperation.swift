//
//  SearchOperation.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/15/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

class FullIndexSearchOperation<T:NSObject>: AbstractSearchOperation<T> {
    
    private var primaryResults:[T]
    private let searchIndex:SearchIndex<T>
    private let searchString:String
    private let searchPredicate:NSPredicate
    
    var finalResults:[T]!
    
    init(primaryResults:[T], searchString:String, searchIndex:SearchIndex<T>, searchPredicate:NSPredicate) {
        self.primaryResults = primaryResults
        self.searchString = searchString
        self.searchIndex = searchIndex
        self.searchPredicate = searchPredicate
    }
    
    
    override func main() {
        if self.cancelled {
            return
        }
        
        let secondaryResults = searchIndex.searchValuesWithString(searchString, searchPredicate: searchPredicate)
        
        if(secondaryResults.isEmpty) { return }
        let tracksSet = Set<T>(primaryResults)
        let resultsSet = Set<T>(secondaryResults)
        let differenceSet = resultsSet.subtract(tracksSet)
        
        primaryResults.appendContentsOf(differenceSet)
        if(!cancelled) {
            finalResults = primaryResults
            
            inThreadCompletionBlock?(finalResults)
        }
        
    }



}
