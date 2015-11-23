//
//  SearchIndex.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/14/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

let indexQueue:NSOperationQueue = {
    var queue = NSOperationQueue()
    queue.name = "com.riaz.fahad.Kyooz.IndexQueue"
    queue.qualityOfService = NSQualityOfService.Background
    return queue
}()

class SearchIndex<T:NSObject> {
    
    let name:String
    private let maxValuesAmount = 200
    
    private var subIndex:[String:SearchIndex<T>]?
    private var values:[SearchIndexEntry<T>]!
    private let indexLevel:Int
    
    convenience init(name:String, indexableValues:[T], keyExtractingBlock:(T)->(String, String)) {
        self.init(name:name, indexableValues:indexableValues, indexLevel:0, keyExtractingBlock: keyExtractingBlock)
    }
    
    init(name:String, indexableValues:[T], indexLevel:Int, keyExtractingBlock:(T)->(String,String)) {
        self.name = name
        self.indexLevel = indexLevel
        if indexableValues.isEmpty {
            return
        }
        let indexBuildingTask = IndexBuildingOperation(parentIndexName:name,
            indexableValues: indexableValues,
            maxValuesAmount: maxValuesAmount,
            indexLevel: indexLevel,
            keyExtractingBlock: keyExtractingBlock)
        indexBuildingTask.completionBlock = {
            if !indexBuildingTask.cancelled {
                if let subIndex = indexBuildingTask.subIndex {
                    self.subIndex = subIndex
                }
                if let values = indexBuildingTask.values {
                    self.values = values
                }
            }
        }
        indexQueue.addOperation(indexBuildingTask)
    }
    
    func searchIndexWithString(searchString:String, searchPredicate:NSPredicate? = nil) -> [T] {
        let predicate = searchPredicate == nil ? createDefaultPredicate(searchString) : searchPredicate!
        if indexLevel < searchString.characters.count {
            if let searchIndex = self.subIndex?[searchString[indexLevel]] {
                return searchIndex.searchIndexWithString(searchString, searchPredicate: predicate)
            }
        }
        return searchValuesWithString(searchString, searchPredicate: predicate, searchAllValues: false)
    }
    
    func searchValuesWithString(searchString:String, searchPredicate:NSPredicate, searchAllValues:Bool = true) -> [T] {
        var filteredValues = [T]()
        
        if let values = self.values {
            if indexLevel >= searchString.characters.count && !searchAllValues {
                filteredValues.appendContentsOf(values.map({ $0.object } ))
            } else {   
                for value in values {
                    if searchPredicate.evaluateWithObject(value) {
                        filteredValues.append(value.object)
                    }
                }
            }
        }
        
        if let subIndex = self.subIndex {
            for (_,index) in subIndex {
                filteredValues.appendContentsOf(index.searchValuesWithString(searchString, searchPredicate: searchPredicate))
            }
        }
        
        return filteredValues
    }
    
    func insertIntoIndex(value:T, primaryKeyValue:(title:String, keyValue:String)) {
        let key = primaryKeyValue.keyValue
        if indexLevel < key.characters.count {
            if let index = self.subIndex?[key[indexLevel]] {
                index.insertIntoIndex(value, primaryKeyValue: primaryKeyValue)
                return
            }
        }
        if values?.append(SearchIndexEntry(object: value, primaryKeyValue: primaryKeyValue)) == nil {
            values = [SearchIndexEntry(object: value, primaryKeyValue: primaryKeyValue)]
        }
    }
    
    private func createDefaultPredicate(searchString:String) -> NSPredicate {
        let searchItems = searchString.componentsSeparatedByString(" ") as [String]
        let andMatchPredicates: [NSPredicate] = searchItems.map { searchString in
            let titleExpression = NSExpression(forKeyPath: "primaryKey")
            let searchStringExpression = NSExpression(forConstantValue: searchString)
            
            let titleSearchComparisonPredicate = NSComparisonPredicate(leftExpression: titleExpression, rightExpression: searchStringExpression, modifier: .DirectPredicateModifier, type: NSPredicateOperatorType.ContainsPredicateOperatorType,
                options: NSComparisonPredicateOptions.NormalizedPredicateOption)
            
            
            return titleSearchComparisonPredicate
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: andMatchPredicates)
    }
}


