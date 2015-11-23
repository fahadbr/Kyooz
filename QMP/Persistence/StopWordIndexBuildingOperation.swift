//
//  StopWordIndexBuildingOperation.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/17/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

//Operation to insert items into the index with the predefined stop words removed
class StopWordIndexBuildingOperation<T:NSObject> : NSOperation {
    
    private let stopWords = ["the ", "a "]
    private let searchIndex:SearchIndex<T>
    private let keyExtractingBlock:(T)->(titleProperty:String,normalizedPrimaryKey:String)
    
    init(searchIndex:SearchIndex<T>, keyExtractingBlock:(T)->(String,String)) {
        self.keyExtractingBlock = keyExtractingBlock
        self.searchIndex = searchIndex
    }

    override func main() {
        if cancelled {
            return
        }
        
        for stopWord in stopWords {
            let results = searchIndex.searchIndexWithString(stopWord.normalizedString)
            for result in results {
                let titleKeyEntry = keyExtractingBlock(result)
                var normalizedKey = titleKeyEntry.normalizedPrimaryKey
                if normalizedKey.hasPrefix(stopWord) {
                    normalizedKey.removeRange(stopWord.startIndex..<stopWord.endIndex)
                    searchIndex.insertIntoIndex(result, primaryKeyValue: (titleKeyEntry.titleProperty, normalizedKey))
                }
            }
        }
    }
}