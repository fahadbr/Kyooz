//
//  SearchResultsController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/25/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

private let fatalErrorAbstractClassMessage = "this is an abstract class, subclass must override and implement this method"

protocol SearchExecutionControllerDelegate: class {
    func searchResultsDidGetUpdated()
}

class SearchExecutionController<T:SearchIndexValue> : NSObject {
    
    let libraryGroup:LibraryGrouping
    
    private (set) var searchResults:[T] = [T]()
    private var searchIndex:SearchIndex<T>?
    private let searchKeys:[String]
    private let defaultSearchQueue:NSOperationQueue
    
    weak var delegate:SearchExecutionControllerDelegate?

    init(libraryGroup:LibraryGrouping, searchKeys:[String]) {
        self.libraryGroup = libraryGroup
        self.searchKeys = searchKeys
        
        defaultSearchQueue = NSOperationQueue()
        defaultSearchQueue.name = "Kyooz.SearchQueue.\(libraryGroup.name)"
        defaultSearchQueue.qualityOfService = NSQualityOfService.UserInteractive
        defaultSearchQueue.maxConcurrentOperationCount = 1

        super.init()
        rebuildSearchIndex()
    }
    

    func executeSearchForStringComponents(searchString:String, stringComponents:[String]) {
        defaultSearchQueue.cancelAllOperations()

        let finalPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: stringComponents.map { searchStringComponent in
            
            let searchStringExpression = NSExpression(forConstantValue: searchStringComponent)
            
            var searchPredicates = [NSPredicate]()
            for searchKey in self.searchKeys {
                let keyExpression = NSExpression(forKeyPath: searchKey)
                let keySearchComparisonPredicate = NSComparisonPredicate(leftExpression: keyExpression, rightExpression: searchStringExpression, modifier: .DirectPredicateModifier, type: NSPredicateOperatorType.ContainsPredicateOperatorType,
                    options: NSComparisonPredicateOptions.NormalizedPredicateOption)
                searchPredicates.append(keySearchComparisonPredicate)
            }
            
            
            return NSCompoundPredicate(orPredicateWithSubpredicates: searchPredicates)
        })
        
        let searchOperation:AbstractResultOperation<[T]> = createSearchOperation(finalPredicate, searchString: searchString)
        
        searchOperation.inThreadCompletionBlock = { [weak self](results) -> Void in
            KyoozUtils.doInMainQueue() {
                //we're updating the search results in the main queue because updating them in the background could conflict with when
                //the table view using this data gets updated
//                if results.isEmpty {
//                    if let oldResults = self?.searchResults where oldResults.isEmpty{
//                        return
//                    }
//                }
                self?.searchResults = results
                self?.delegate?.searchResultsDidGetUpdated()
            }
        }
        
        defaultSearchQueue.addOperation(searchOperation)
    }
    
    func clearSearchResults() {
        searchResults = [T]()
    }
    
    func performAfterSearch(block:()->()) {
        defaultSearchQueue.addOperationWithBlock(block)
    }
    
    func rebuildSearchIndex() {
        fatalError(fatalErrorAbstractClassMessage)
    }
    
    private func createSearchOperation(searchPredicate:NSPredicate, searchString:String) -> AbstractResultOperation<[T]> {
        fatalError(fatalErrorAbstractClassMessage)
    }
    
}

final class IPodLibrarySearchExecutionController : SearchExecutionController<AudioEntity> {
    
    override init(libraryGroup: LibraryGrouping, searchKeys: [String]) {
        super.init(libraryGroup: libraryGroup, searchKeys: searchKeys)
    }
    
    override func rebuildSearchIndex() {
        self.searchIndex = nil
        if let values:[AudioEntity] = libraryGroup == LibraryGrouping.Songs ? libraryGroup.baseQuery.items : libraryGroup.baseQuery.collections {
            let titlePropertyName = MPMediaItem.titlePropertyForGroupingType(libraryGroup.groupingType)
            let indexBuildingOp = IndexBuildingOperation(parentIndexName: libraryGroup.name, valuesToIndex: values, maxValuesAmount: 200, keyExtractingBlock: { (entity:AudioEntity) -> (String, String) in
                if let primaryKey = entity.titleForGrouping(self.libraryGroup)?.normalizedString {
                    return (titlePropertyName, primaryKey)
                }
                return (titlePropertyName,"null")
            })
            
            indexBuildingOp.inThreadCompletionBlock = { (result) -> Void in
                KyoozUtils.doInMainQueue() {
                    self.searchIndex = result
                    Logger.debug("finished building \(result.name) index")
                }
            }
            
            indexQueue.addOperation(indexBuildingOp)
        }
    }
    
    private override func createSearchOperation(searchPredicate: NSPredicate, searchString: String) -> AbstractResultOperation<[AudioEntity]> {
        if let searchIndex = self.searchIndex {
            return IndexSearchOperation(searchIndex: searchIndex, searchPredicate: searchPredicate, searchString: searchString)
        } else {
            return AdHocIPodLibrarySearchOperation(group: libraryGroup, searchString: searchString, searchPredicate: searchPredicate)
        }
    }
    
    
}