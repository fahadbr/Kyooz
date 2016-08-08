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
    func searchResultsDidGetUpdated(_ searchExecutionController:SearchExecutionController)
    func searchDidComplete(_ searchExecutionController:SearchExecutionController)
}

class SearchExecutionController : NSObject {
    
    
    let libraryGroup:LibraryGrouping
    
    override var description: String {
        return libraryGroup.name
    }
    
    var searchInProgress:Bool = false
    
    private (set) var searchResults:[AudioEntity] = [AudioEntity]()
    private (set) var searchIndex:SearchIndex<AudioEntity>? {
        didSet {
            if let previousSearchParams = self.previousSearchParams {
                executeSearchForStringComponents(previousSearchParams.searchString, stringComponents: previousSearchParams.stringComponents)
            }
        }
    }
    let searchKeys:[String]
    private let defaultSearchQueue:OperationQueue
    
    private var previousSearchParams:(searchString:String, stringComponents:[String])?
    weak var delegate:SearchExecutionControllerDelegate?

    init(libraryGroup:LibraryGrouping, searchKeys:[String]) {
        self.libraryGroup = libraryGroup
        self.searchKeys = searchKeys
        self.defaultSearchQueue = OperationQueue()
        super.init()
        
        defaultSearchQueue.name = "Kyooz.SearchQueue.\(description)"
        defaultSearchQueue.qualityOfService = QualityOfService.userInitiated
        defaultSearchQueue.maxConcurrentOperationCount = 1
        rebuildSearchIndex()
    }
    

    func executeSearchForStringComponents(_ searchString:String, stringComponents:[String]) {
        defaultSearchQueue.cancelAllOperations()

        let finalPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: stringComponents.map { searchStringComponent in
            
            let searchStringExpression = NSExpression(forConstantValue: searchStringComponent)
            
            var searchPredicates = [NSPredicate]()
            for searchKey in self.searchKeys {
                let keyExpression = NSExpression(forKeyPath: searchKey)
                let keySearchComparisonPredicate = NSComparisonPredicate(leftExpression: keyExpression, rightExpression: searchStringExpression, modifier: .direct, type: NSComparisonPredicate.Operator.contains,
                    options: NSComparisonPredicate.Options.normalized)
                searchPredicates.append(keySearchComparisonPredicate)
            }
            
            
            return NSCompoundPredicate(orPredicateWithSubpredicates: searchPredicates)
        })
        
        let searchOperation:AbstractResultOperation<[AudioEntity]>
        if let searchIndex = self.searchIndex {
            searchOperation = IndexSearchOperation(searchIndex: searchIndex, searchPredicate: finalPredicate, searchString: searchString)
        } else if let adHocSearchOp = createAdHocSearchOperation(finalPredicate, searchString: searchString) {
            searchOperation = adHocSearchOp
        } else {
            return
        }
        
        searchOperation.inThreadCompletionBlock = { (results) -> Void in
            KyoozUtils.doInMainQueue() {
                //we're updating the search results in the main queue because updating them in the background could conflict with when
                //the table view using this data gets updated
                guard !results.isEmpty || !self.searchResults.isEmpty else {
                    return
                }
                self.searchResults = results
                self.delegate?.searchResultsDidGetUpdated(self)
            }
        }
        
        defaultSearchQueue.addOperation(searchOperation)
        searchInProgress = true
        defaultSearchQueue.addOperation() {
            KyoozUtils.doInMainQueue() {
                self.searchInProgress = false
                self.delegate?.searchDidComplete(self)
            }
        }
        
        previousSearchParams = (searchString, stringComponents)
    }
    
    func clearSearchResults() {
        searchResults = [AudioEntity]()
    }
    
    func performAfterSearch(_ block:()->()) {
        defaultSearchQueue.addOperation(block)
    }
    
    final func rebuildSearchIndex() {
        guard let indexBuildingOp = createIndexBuildingOperation() else {
            Logger.error("failed to create index building operation")
            return
        }
        
        indexBuildingOp.inThreadCompletionBlock = { (result) -> Void in
            KyoozUtils.doInMainQueue() {
                self.searchIndex = result
                Logger.debug("finished building \(result.name) index")
            }
        }
        
        indexQueue.addOperation(indexBuildingOp)
    }
    
    func createIndexBuildingOperation() -> IndexBuildingOperation<AudioEntity>? {
        fatalError(fatalErrorAbstractClassMessage)
    }
    
    func createAdHocSearchOperation(_ searchPredicate:NSPredicate, searchString:String) -> AbstractResultOperation<[AudioEntity]>? {
        return nil
    }
    
}

final class IPodLibrarySearchExecutionController : SearchExecutionController {
    override func createIndexBuildingOperation() -> IndexBuildingOperation<AudioEntity>? {
        let query = libraryGroup.baseQuery
        guard let values:[AudioEntity] = libraryGroup == LibraryGrouping.Songs ? query.items : query.collections else {
            return nil
        }
        
        let titlePropertyName = MPMediaItem.titleProperty(forGroupingType: libraryGroup.groupingType)
        let indexBuildingOp = IndexBuildingOperation(parentIndexName: libraryGroup.name, valuesToIndex: values, maxValuesAmount: 200, keyExtractingBlock: { (entity:AudioEntity) -> (String, String) in
            if let primaryKey = entity.titleForGrouping(self.libraryGroup)?.normalizedString {
                return (titlePropertyName, primaryKey)
            }
            return (titlePropertyName,"null")
        })
        return indexBuildingOp

    }
    
    override func createAdHocSearchOperation(_ searchPredicate: NSPredicate, searchString: String) -> AbstractResultOperation<[AudioEntity]>? {
        return AdHocIPodLibrarySearchOperation(group: libraryGroup, searchString: searchString, searchPredicate: searchPredicate)
    }
}

final class KyoozPlaylistSearchExecutionController : SearchExecutionController {
    
    init() {
        super.init(libraryGroup: LibraryGrouping.Playlists, searchKeys: ["name"])
        NotificationCenter.default.addObserver(self, selector: #selector(super.rebuildSearchIndex), name: NSNotification.Name(rawValue: KyoozPlaylistManager.PlaylistSetUpdate), object: KyoozPlaylistManager.instance)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var description: String {
        return "KYOOZ PLAYLIST"
    }
    
    override func createIndexBuildingOperation() -> IndexBuildingOperation<AudioEntity>? {
        guard let values:[AudioEntity] = KyoozPlaylistManager.instance.playlists.array as? [AudioEntity] else {
            return nil
        }
        let titlePropertyName = searchKeys.first!
        let indexBuildingOp = IndexBuildingOperation(parentIndexName: "KYOOZ " + libraryGroup.name, valuesToIndex: values, maxValuesAmount: 200, keyExtractingBlock: { (entity:AudioEntity) -> (String, String) in
            if let primaryKey = entity.titleForGrouping(self.libraryGroup)?.normalizedString {
                return (titlePropertyName, primaryKey)
            }
            return (titlePropertyName,"null")
        })
        
        return indexBuildingOp
    }
    
    override func createAdHocSearchOperation(_ searchPredicate: NSPredicate, searchString: String) -> AbstractResultOperation<[AudioEntity]> {
        return AdHocKyoozPlaylistSearchOperation(primaryKeyName: searchKeys.first!, searchPredicate: searchPredicate, searchString: searchString)
    }
}
