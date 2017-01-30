//
//  IndexSearchOperation.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/25/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

final class IndexSearchOperation<T:SearchIndexValue> : AbstractResultOperation<[T]> {
    
    let searchIndex:SearchIndex<T>
    let searchPredicate:NSPredicate
    let searchString:String

    init(searchIndex:SearchIndex<T>, searchPredicate:NSPredicate, searchString:String) {
        self.searchIndex = searchIndex
        self.searchPredicate = searchPredicate
        self.searchString = searchString
    }
    
    
    override func main() {
        if isCancelled { return }
        var results = searchIndex.searchIndexWithString(searchString, searchPredicate:searchPredicate)
        
        if isCancelled { return }
        
        inThreadCompletionBlock?(results)
        
        if isCancelled { return }
        
        let secondaryResults = searchIndex.searchValuesWithString(searchString, searchPredicate: searchPredicate)
        
        if(secondaryResults.isEmpty) { return }
		
		let tracksSet = NSSet(array: results)
		let resultsSet = NSMutableSet(array: secondaryResults)
		resultsSet.minus(tracksSet as Set<NSObject>)
		guard let differences = resultsSet.allObjects as? [T] else {
			return
		}
		
        results.append(contentsOf: differences)
        
        if isCancelled { return }
            
        inThreadCompletionBlock?(results)
    }
}
