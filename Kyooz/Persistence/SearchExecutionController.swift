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

class SearchExecutionController : NSObject {
    
    let libraryGroup:LibraryGrouping
    
    override var description: String {
        return libraryGroup.name
    }
    
    private (set) var searchResults:[AudioEntity] = [AudioEntity]()
    private var searchIndex:SearchIndex<AudioEntity>? {
        didSet {
            if let previousSearchParams = self.previousSearchParams {
                executeSearchForStringComponents(previousSearchParams.searchString, stringComponents: previousSearchParams.stringComponents)
            }
        }
    }
    private let searchKeys:[String]
    private let defaultSearchQueue:NSOperationQueue
    
    private var previousSearchParams:(searchString:String, stringComponents:[String])?
    weak var delegate:SearchExecutionControllerDelegate?

    init(libraryGroup:LibraryGrouping, searchKeys:[String]) {
        self.libraryGroup = libraryGroup
        self.searchKeys = searchKeys
        self.defaultSearchQueue = NSOperationQueue()
        super.init()
        
        defaultSearchQueue.name = "Kyooz.SearchQueue.\(description)"
        defaultSearchQueue.qualityOfService = NSQualityOfService.UserInteractive
        defaultSearchQueue.maxConcurrentOperationCount = 1
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
        
        let searchOperation:AbstractResultOperation<[AudioEntity]> = self.createSearchOperation(finalPredicate, searchString: searchString)
        
        searchOperation.inThreadCompletionBlock = { [weak self](results) -> Void in
            KyoozUtils.doInMainQueue() {
                //we're updating the search results in the main queue because updating them in the background could conflict with when
                //the table view using this data gets updated
                if results.isEmpty {
                    if let oldResults = self?.searchResults where oldResults.isEmpty{
                        return
                    }
                }
                self?.searchResults = results
                self?.delegate?.searchResultsDidGetUpdated()
            }
        }
        
        defaultSearchQueue.addOperation(searchOperation)
        previousSearchParams = (searchString, stringComponents)
    }
    
    func clearSearchResults() {
        searchResults = [AudioEntity]()
    }
    
    func performAfterSearch(block:()->()) {
        defaultSearchQueue.addOperationWithBlock(block)
    }
    
    func rebuildSearchIndex() {
        fatalError(fatalErrorAbstractClassMessage)
    }
    
    private func createSearchOperation(searchPredicate:NSPredicate, searchString:String) -> AbstractResultOperation<[AudioEntity]> {
        fatalError(fatalErrorAbstractClassMessage)
    }
    
}

final class IPodLibrarySearchExecutionController : SearchExecutionController {
    
    
    override func rebuildSearchIndex() {
        let query = libraryGroup.baseQuery
        if let values:[AudioEntity] = libraryGroup == LibraryGrouping.Songs ? query.items : query.collections {
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

final class KyoozPlaylistSearchExecutionController : SearchExecutionController {
    
    init() {
        super.init(libraryGroup: LibraryGrouping.Playlists, searchKeys: ["name"])
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.rebuildSearchIndex), name: KyoozPlaylistManager.PlaylistSetUpdate, object: KyoozPlaylistManager.instance)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override var description: String {
        return "KYOOZ PLAYLIST"
    }
    
    override func rebuildSearchIndex() {
        if let values:[AudioEntity] = KyoozPlaylistManager.instance.playlists.array as? [AudioEntity] {
            let titlePropertyName = searchKeys.first!
            let indexBuildingOp = IndexBuildingOperation(parentIndexName: "KYOOZ " + libraryGroup.name, valuesToIndex: values, maxValuesAmount: 200, keyExtractingBlock: { (entity:AudioEntity) -> (String, String) in
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
            return AdHocKyoozPlaylistSearchOperation(primaryKeyName: searchKeys.first!, searchPredicate: searchPredicate, searchString: searchString)
        }
    }
}