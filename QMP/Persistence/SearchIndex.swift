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

final class SearchIndex<T:NSObject> {
    
    let name:String
    
    private var subIndex:[String:SearchIndex<T>]?
    private var sameLevelValues:Set<SearchIndexEntry<T>>?
    private let indexLevel:Int
    
    convenience init(name:String, sameLevelValues:Set<SearchIndexEntry<T>>?, subIndex:[String:SearchIndex<T>]?) {
        self.init(name:name, indexLevel:0, sameLevelValues:sameLevelValues, subIndex:subIndex)
    }
    
    init(name:String, indexLevel:Int, sameLevelValues:Set<SearchIndexEntry<T>>?, subIndex:[String:SearchIndex<T>]?) {
        self.name = name
        self.indexLevel = indexLevel
        if (sameLevelValues == nil || sameLevelValues!.isEmpty) && (subIndex == nil || subIndex!.isEmpty) {
//            fatalError("Cannot create a SearchIndex with both sameLevelValues and subIndex as nil or empty")
        }
        
        self.subIndex = subIndex
        self.sameLevelValues = sameLevelValues
        
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
        
        if let values = self.sameLevelValues {
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
    
    func insertIntoIndex(entry:SearchIndexEntry<T>) {
        let key = entry.primaryKey
        if indexLevel < key.characters.count {
            if let index = self.subIndex?[key[indexLevel]] {
                index.insertIntoIndex(entry)
                return
            }
        }
        if sameLevelValues?.insert(entry) == nil {
            sameLevelValues = [entry]
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


