//
//  IndexBuildingOperation.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/27/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

final class IndexBuildingOperation<T:SearchIndexValue> : AbstractResultOperation<SearchIndex<T>> {
    
    fileprivate let stopWords = ["the ", "a "]
    
    fileprivate let valuesToIndex:[T]
    fileprivate let keyExtractingBlock:(T)->(titleProperty:String,normalizedPrimaryKey:String)
    fileprivate let maxValuesAmount:Int
    fileprivate let parentIndexName:String
    
    init(parentIndexName:String, valuesToIndex:[T], maxValuesAmount:Int, keyExtractingBlock:@escaping (T)->(String, String)) {
        self.parentIndexName = parentIndexName
        self.valuesToIndex = valuesToIndex
        self.maxValuesAmount = maxValuesAmount
        self.keyExtractingBlock = keyExtractingBlock
    }
    
    override func main() {
        if isCancelled { return }
        
        let fromValueIndexBuilder:IndexBuilder<T,T> = FromValuesIndexBuilder(maxValuesAmount: maxValuesAmount, keyExtractingBlock: keyExtractingBlock)
        fromValueIndexBuilder.originatingOperation = self
        let fromEntryIndexBuilder:IndexBuilder<T,SearchIndexEntry<T>> = FromEntriesIndexBuilder(maxValuesAmount:maxValuesAmount)
        fromEntryIndexBuilder.originatingOperation = self
        
        let finalIndex:SearchIndex<T>
        do {
            finalIndex = try fromValueIndexBuilder.buildIndex(parentIndexName, valuesToIndex: valuesToIndex, indexLevel: 0, nextIndexBuilder: fromEntryIndexBuilder)
        } catch IndexBuildError.cancelled {
            Logger.debug("Index build was cancelled")
            return
        } catch {
            Logger.debug("Unknown error occurred")
            return
        }
        
        if isCancelled { return }
        
        for stopWord in stopWords {
            if isCancelled { return }
            let results = finalIndex.searchIndexWithString(stopWord.normalizedString)
            
            for result in results {
                if isCancelled { return }
                let titleKeyEntry = keyExtractingBlock(result)
                var normalizedKey = titleKeyEntry.normalizedPrimaryKey
                if normalizedKey.hasPrefix(stopWord) {
                    normalizedKey.removeSubrange(stopWord.startIndex ..< stopWord.endIndex)
                    finalIndex.insertIntoIndex(SearchIndexEntry(object: result, primaryKeyValue: (titleKeyEntry.titleProperty, normalizedKey)))
                }
            }
        }
        
        inThreadCompletionBlock?(finalIndex)
    }
    
}

fileprivate enum IndexBuildError : Error {
    case cancelled
}

fileprivate class IndexBuilder<BASE:SearchIndexValue,INPUT> {
    
    weak var originatingOperation:Operation?
    
    fileprivate let maxValuesAmount:Int
    
    init(maxValuesAmount:Int) {
        self.maxValuesAmount = maxValuesAmount
    }
    
    fileprivate final func buildIndex(_ title:String, valuesToIndex:[INPUT], indexLevel:Int, nextIndexBuilder:IndexBuilder<BASE, SearchIndexEntry<BASE>>) throws -> SearchIndex<BASE> {
        let isLastIndexLevel:Bool = valuesToIndex.count <= maxValuesAmount
        var valueDict = [String:[SearchIndexEntry<BASE>]]()
        var sameLevelValues = [SearchIndexEntry<BASE>]()
        
        for value in valuesToIndex {
            
            if originatingOperation?.isCancelled ?? true {
                throw IndexBuildError.cancelled
            }
            
            let entry = getSearchIndexEntry(value)
            let primaryKey = entry.primaryKey
            if !isLastIndexLevel && indexLevel < primaryKey.characters.count {
                if valueDict[primaryKey[indexLevel]]?.append(entry) == nil {
                    valueDict[primaryKey[indexLevel]] = [entry]
                }
            } else {
                sameLevelValues.append(entry)
            }
        }
        
        var subIndex:[String:SearchIndex<BASE>]?
        var sameLevelValuesSet:Set<SearchIndexEntry<BASE>>?
        if !isLastIndexLevel {
            subIndex = [String:SearchIndex<BASE>]()
            let nextIndexLevel = indexLevel + 1
            for (characterIndex, values) in valueDict {
                if let cancelled = originatingOperation?.isCancelled, cancelled == true {
                    throw IndexBuildError.cancelled
                }
                
                subIndex![characterIndex] = try nextIndexBuilder.buildIndex("\(title)[\(characterIndex)]",
                                                                            valuesToIndex: values,
                                                                            indexLevel: nextIndexLevel,
                                                                            nextIndexBuilder:nextIndexBuilder)
            }
        }
        if !sameLevelValues.isEmpty {
            sameLevelValuesSet = Set(sameLevelValues)
        }
        
        if let cancelled = originatingOperation?.isCancelled, cancelled == true {
            throw IndexBuildError.cancelled
        }
        
        return SearchIndex(name: title,
                           indexLevel: indexLevel,
                           sameLevelValues: sameLevelValuesSet,
                           subIndex: subIndex)
    }
    
    fileprivate func getSearchIndexEntry(_ value:INPUT) -> SearchIndexEntry<BASE> {
        fatalError()
    }
}

fileprivate class FromValuesIndexBuilder<T:SearchIndexValue> : IndexBuilder<T, T> {
    
    fileprivate let keyExtractingBlock:(T)->(titleProperty:String,normalizedPrimaryKey:String)
    
    init(maxValuesAmount: Int, keyExtractingBlock: @escaping (T)->(String,String)) {
        self.keyExtractingBlock = keyExtractingBlock
        super.init(maxValuesAmount: maxValuesAmount)
    }
    
    override func getSearchIndexEntry(_ value: T) -> SearchIndexEntry<T> {
        return SearchIndexEntry(object: value, primaryKeyValue: keyExtractingBlock(value))
    }
}

fileprivate class FromEntriesIndexBuilder<T:SearchIndexValue> : IndexBuilder<T, SearchIndexEntry<T>> {
    
    override init(maxValuesAmount: Int) {
        super.init(maxValuesAmount: maxValuesAmount)
    }
    
    override func getSearchIndexEntry(_ value: SearchIndexEntry<T>) -> SearchIndexEntry<T> {
        return value
    }
    
}

