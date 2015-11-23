//
//  IndexBuildingOperation.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/16/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

class IndexBuildingOperation<T:NSObject> : NSOperation {
    
    var progress:Int = 0
    
    var subIndex:[String:SearchIndex<T>]?
    var values:[SearchIndexEntry<T>]?
    
    private let indexableValues:[T]
    private let keyExtractingBlock:(T)->(titleProperty:String,normalizedPrimaryKey:String)
    private let maxValuesAmount:Int
    private let indexLevel:Int
    private let isFinalLevel:Bool
    private let parentIndexName:String
    
    init(parentIndexName:String, indexableValues:[T], maxValuesAmount:Int, indexLevel:Int, keyExtractingBlock:(T)->(String,String)) {
        self.indexableValues = indexableValues
        self.keyExtractingBlock = keyExtractingBlock
        self.maxValuesAmount = maxValuesAmount
        self.indexLevel = indexLevel
        self.parentIndexName = parentIndexName
        self.isFinalLevel = indexableValues.count <= maxValuesAmount
        if !isFinalLevel {
            subIndex = [String:SearchIndex<T>]()
        }
    }
    
    
    override func main() {
        if cancelled {
            return
        }
        
        var tempIndex = [String:[T]]()
        
        for value in indexableValues {
            let keyValue = keyExtractingBlock(value)
            let normalizedPrimaryKey = keyValue.normalizedPrimaryKey
            
            if subIndex != nil && indexLevel < normalizedPrimaryKey.characters.count {                
                if tempIndex[normalizedPrimaryKey[indexLevel]]?.append(value) == nil {
                    tempIndex[normalizedPrimaryKey[indexLevel]] = [value]
                }
            } else if values?.append(SearchIndexEntry(object: value, primaryKeyValue: keyValue)) == nil {
                values = [SearchIndexEntry(object: value, primaryKeyValue: keyValue)]
            }
            progress++
        }
        
        if subIndex != nil {
            let nextIndexLevel = indexLevel + 1
            for (key, value) in tempIndex {
                subIndex![key] = SearchIndex(name:"\(parentIndexName)[\(key)]",indexableValues: value, indexLevel: nextIndexLevel, keyExtractingBlock: keyExtractingBlock)
            }
        }
        
    }
    
}