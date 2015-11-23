//
//  MediaLibrarySearchResultsUpdater.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/8/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

class MediaLibrarySearchTableViewController : AbstractMediaEntityTableViewController, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {

    static let instance = MediaLibrarySearchTableViewController()
    
    private static let groups = [LibraryGrouping.Artists, LibraryGrouping.Albums, LibraryGrouping.Songs, LibraryGrouping.Playlists]
    
    //MARK: - Properties
    var searchController:UISearchController!
    
    private let maxRowsPerSection = [LibraryGrouping.Artists:3, LibraryGrouping.Albums:4, LibraryGrouping.Songs:6, LibraryGrouping.Playlists:3]
    private let groups:[LibraryGrouping] = MediaLibrarySearchTableViewController.groups
    private let searchKeysByGrouping = [
        LibraryGrouping.Artists : [MPMediaItemPropertyAlbumArtist],
        LibraryGrouping.Albums : [MPMediaItemPropertyAlbumTitle, MPMediaItemPropertyAlbumArtist],
        LibraryGrouping.Songs : [MPMediaItemPropertyTitle, MPMediaItemPropertyAlbumTitle, MPMediaItemPropertyAlbumArtist],
        LibraryGrouping.Playlists : [MPMediaPlaylistPropertyName]]
    
    private let searchQueues:[LibraryGrouping:NSOperationQueue] = {
        var queueDict = [LibraryGrouping:NSOperationQueue]()
        for group in MediaLibrarySearchTableViewController.groups {
            let queue = NSOperationQueue()
            queue.name = "com.riaz.fahad.Kyooz.SearchQueue.\(group.name)"
            queue.qualityOfService = NSQualityOfService.UserInteractive
            queue.maxConcurrentOperationCount = 1
            queueDict[group] = queue
        }
        return queueDict
    }()
    
    private let completionQueue:NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.name = "com.riaz.fahad.Kyooz.SearchCompletionQueue"
        queue.qualityOfService = NSQualityOfService.UserInteractive
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    private (set) var indexIsLoaded = false    
    private var sections = [LibraryGrouping]()
    private var searchResults = [LibraryGrouping:[MPMediaEntity]]()
    private var searchIndicies = [LibraryGrouping:SearchIndex<MPMediaEntity>]()
    private var tapGestureRecognizers = [LibraryGrouping:UITapGestureRecognizer]()
    private var selectedHeader:LibraryGrouping?
    private var shouldReloadTableViewAfterSearchCompleted = true
    
    //MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(MediaCollectionTableViewCell.self, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
        tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
    }
    
    //MARK: - Table View Datasource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }

    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let group:LibraryGrouping
        let isOnlySection:Bool
        if let selectedHeader = self.selectedHeader {
            group = selectedHeader
            isOnlySection = true
        } else {
            group = sections[section]
            isOnlySection = sections.count == 1 && shouldReloadTableViewAfterSearchCompleted
        }
        
        guard let count = searchResults[group]?.count, let maxRows = maxRowsPerSection[group] else {
            return 0
        }
        
        return ((count > maxRows) && !isOnlySection) ? maxRows : count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].name
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let group = sections[indexPath.section]
        let reuseIdentifier = group === LibraryGrouping.Albums ? ImageTableViewCell.reuseIdentifier : MediaCollectionTableViewCell.reuseIdentifier
        
        guard let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier), let results = searchResults[group] else {
            return UITableViewCell()
        }
        
        guard indexPath.row < results.count else {
            return UITableViewCell()
        }
        let entity = results[indexPath.row]
        if let configurableCell = cell as? ConfigurableAudioTableCell {
            configurableCell.configureCellForItems(entity, mediaGroupingType: group.groupingType)
        } else {
            cell.textLabel?.text = entity.titleForGrouping(group.groupingType)
        }
        
        return cell
    }
    
    //MARK: - Table View Delegate
    //MARK: header configuration
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let group = sections[section]
        guard let view = NSBundle.mainBundle().loadNibNamed("SearchResultsHeaderView", owner: self, options: nil)?.first as? SearchResultsHeaderView else {
            return nil
        }
        view.headerTitleLabel.text = group.name.uppercaseString
        if sections.count > 1 || selectedHeader != nil {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "didTapHeaderView:")
            view.addGestureRecognizer(tapGestureRecognizer)
            view.disclosureContainerView.hidden = false
            tapGestureRecognizers[group] = tapGestureRecognizer
        } else {
            view.disclosureContainerView.hidden = true
        }
        
        view.applyRotation(shouldExpand: selectedHeader != nil && group === selectedHeader!)
        
        return view
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
    
    //MARK: other configuration
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let group = sections[indexPath.section]
        
        guard let entity = searchResults[group]?[indexPath.row] else {
            return
        }
        
        if let item = entity as? MPMediaItem where group === LibraryGrouping.Songs {
            audioQueuePlayer.playNowWithCollection(mediaCollection: MPMediaItemCollection(items: [item]), itemToPlay: item)
            return
        }
        
        let title = entity.titleForGrouping(group.groupingType)
        let propertyName = MPMediaItem.persistentIDPropertyForGroupingType(group.groupingType)
        let propertyValue = NSNumber(unsignedLongLong: entity.persistentID)
        
        let filterQuery = MPMediaQuery(filterPredicates: group.nextGroupLevel!.baseQuery.filterPredicates)
        filterQuery.addFilterPredicate(MPMediaPropertyPredicate(value: propertyValue, forProperty: propertyName))
        filterQuery.groupingType = group.nextGroupLevel!.groupingType
        
        //go to specific album track view controller if we are selecting an album collection
        
        let vc:AbstractMediaEntityTableViewController!
        
        if group === LibraryGrouping.Albums {
            let albumTrackVc = UIStoryboard.albumTrackTableViewController()
            albumTrackVc.albumCollection = entity as! MPMediaItemCollection
            vc = albumTrackVc
        } else {
            vc = UIStoryboard.mediaCollectionTableViewController()
            vc.title = title
        }
        
        vc.filterQuery = filterQuery
        vc.libraryGroupingType = group.nextGroupLevel
        
        (presentingViewController as? UINavigationController)?.popToRootViewControllerAnimated(false)
        RootViewController.instance.searchController.active = false
        (presentingViewController as? UINavigationController)?.pushViewController(vc, animated: true)
    }
    //MARK: - SCROLL DELEGATE
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        searchController.searchBar.resignFirstResponder()
    }
    
    //MARK: - AbstractMediaEntityTableViewController methods
    override func reloadSourceData() {
        //empty implementation
    }
    
    override func reloadAllData() {
        initializeIndicies()
    }
    
    override func reloadTableViewData() {
        reloadSections()
        if shouldReloadTableViewAfterSearchCompleted {
            if NSThread.isMainThread() {
                super.reloadTableViewData()
            } else {
                dispatch_async(dispatch_get_main_queue(), super.reloadTableViewData)
            }
        }
    }
    
    
    
    override func getMediaItemsForIndexPath(indexPath: NSIndexPath) -> [AudioTrack] {
        RootViewController.instance.searchController.searchBar.resignFirstResponder()
        let group = sections[indexPath.section]
        guard let results = searchResults[group] else {
            return [AudioTrack]()
        }
        if results.count <= indexPath.row {
            return [AudioTrack]()
        }
        let entity = results[indexPath.row]
        
        if let collection = entity as? MPMediaItemCollection {
            return collection.items
        } else if let mediaItem = entity as? MPMediaItem {
            return [mediaItem]
        }
        
        return [AudioTrack]()
    }

    
    //MARK: - Search Bar Delegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    //MARK: - Search Controller delegate
    func didDismissSearchController(searchController: UISearchController) {
        searchResults.removeAll()
        selectedHeader = nil
    }
    
    //MARK: - Search Results Updating
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        shouldReloadTableViewAfterSearchCompleted = true
        updateSearchResults(searchController)
    }
    
    //MARK: - class functions
    private func updateSearchResults(searchController: UISearchController) {
        
        if let text = searchController.searchBar.text?.normalizedString where !text.isEmpty {
            
            searchResults.removeAll()
            
            let searchItems = text.componentsSeparatedByString(" ") as [String]
            
            for group in groups {
                
                if selectedHeader != nil && selectedHeader! !== group {
                    continue
                }
                
                let andMatchPredicates: [NSPredicate] = searchItems.map { searchString in
                    
                    let searchStringExpression = NSExpression(forConstantValue: searchString)
                    
                    guard let searchKeys = searchKeysByGrouping[group] else {
                        Logger.debug("No search keys for group \(group.name)")
                        return NSPredicate()
                    }
                    
                    var searchPredicates = [NSPredicate]()
                    for searchKey in searchKeys {
                        let keyExpression = NSExpression(forKeyPath: searchKey)
                        let keySearchComparisonPredicate = NSComparisonPredicate(leftExpression: keyExpression, rightExpression: searchStringExpression, modifier: .DirectPredicateModifier, type: NSPredicateOperatorType.ContainsPredicateOperatorType,
                            options: NSComparisonPredicateOptions.NormalizedPredicateOption)
                        searchPredicates.append(keySearchComparisonPredicate)
                    }
                    
                    
                    return NSCompoundPredicate(orPredicateWithSubpredicates: searchPredicates)
                }
                
                let finalCompoundPredicate =  NSCompoundPredicate(andPredicateWithSubpredicates: andMatchPredicates)
                
                guard let searchQueue = searchQueues[group] else {
                    Logger.debug("No search queue found for group \(group.name)")
                    return
                }
                searchQueue.cancelAllOperations()
                
                let completionBlock = { (results:[MPMediaEntity]) -> Void in
                    self.completionQueue.addOperationWithBlock() {
                        dispatch_sync(dispatch_get_main_queue()) {
                            self.searchResults[group] = results
                            self.reloadTableViewData()
                        }
                    }
                }
                
                if indexIsLoaded {
                    searchResults[group] = startSearchForMediaGrouping(text, group:group, searchPredicate: finalCompoundPredicate, searchQueue: searchQueue, inThreadCompletionBlock: completionBlock)
                } else {
                    performAdHocSearch(text, group: group, searchPredicate: finalCompoundPredicate, searchQueue: searchQueue, inThreadCompletionBlock: completionBlock)
                }
            }
            
            reloadTableViewData()
        } else {
            selectedHeader = nil
            searchResults.removeAll()
        }
        
    }
    
    
    private func performAdHocSearch(searchString:String, group:LibraryGrouping, searchPredicate:NSPredicate, searchQueue:NSOperationQueue, inThreadCompletionBlock:([MPMediaEntity])->()) {
        let searchOperation = AdHocIPodLibrarySearchOperation(group: group, searchString: searchString, searchPredicate: searchPredicate)
        searchOperation.inThreadCompletionBlock = inThreadCompletionBlock
        searchQueue.addOperation(searchOperation)
    }
    
    private func startSearchForMediaGrouping(searchString:String, group:LibraryGrouping, searchPredicate:NSPredicate, searchQueue:NSOperationQueue, inThreadCompletionBlock:([MPMediaEntity])->()) -> [MPMediaEntity] {
        guard let searchIndex = searchIndicies[group] else {
            return [MPMediaEntity]()
        }
        let primaryResults = searchIndex.searchIndexWithString(searchString, searchPredicate:searchPredicate)
        
        if let maxRows = maxRowsPerSection[group] where primaryResults.count >= maxRows && selectedHeader == nil {
            return primaryResults
        }
        
        let secondarySearchOperation = FullIndexSearchOperation(primaryResults: primaryResults, searchString: searchString, searchIndex: searchIndex, searchPredicate: searchPredicate)
        secondarySearchOperation.inThreadCompletionBlock = inThreadCompletionBlock
        secondarySearchOperation.name = searchString
        searchQueue.addOperation(secondarySearchOperation)
        
        return primaryResults
    }
    
    func initializeIndicies() {
        Logger.debug("Search Index Rebuild has been triggered")
        indexIsLoaded = false
        for grouping in groups {
            if let entities:[MPMediaEntity] = grouping == LibraryGrouping.Songs ? grouping.baseQuery.items : grouping.baseQuery.collections {
                searchIndicies[grouping] = SearchIndex(name:grouping.name, indexableValues: entities, keyExtractingBlock: getKeyExtractorForLibraryGrouping(grouping))
            }
        }
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            indexQueue.waitUntilAllOperationsAreFinished()
            Logger.debug("Search Index has finished building")
            for grouping in self.groups {
                if let index = self.searchIndicies[grouping] {
                    indexQueue.addOperation(StopWordIndexBuildingOperation(searchIndex: index, keyExtractingBlock: self.getKeyExtractorForLibraryGrouping(grouping)))
                }
            }
            indexQueue.waitUntilAllOperationsAreFinished()
            Logger.debug("Stop word indexing has completed")
            self.indexIsLoaded = true
        }
    }
    
    private func getKeyExtractorForLibraryGrouping(grouping:LibraryGrouping) -> ((MPMediaEntity) -> (String, String)) {
        let titlePropertyName = MPMediaItem.titlePropertyForGroupingType(grouping.groupingType)
        return { (entity:MPMediaEntity) -> (String,String) in
            if let primaryKey = entity.titleForGrouping(grouping.groupingType)?.normalizedString {
                return (titlePropertyName, primaryKey)
            }
            return (titlePropertyName,"null")
        }
    }
    
    private func reloadSections() {
        var newSections = [LibraryGrouping]()
        if let selectedHeader = self.selectedHeader {
            newSections = [selectedHeader]
        } else {
            for group in groups {
                if let results = searchResults[group] {
                    if !results.isEmpty {
                        newSections.append(group)
                    }
                }
            }
        }
        sections = newSections
    }
    
    //MARK: tap gesture handler
    func didTapHeaderView(sender:UITapGestureRecognizer) {
        //queue for serial processing for this function only in the background
        struct function {
            static let queue:NSOperationQueue = {
                let queue = NSOperationQueue()
                queue.qualityOfService = NSQualityOfService.UserInteractive
                queue.maxConcurrentOperationCount = 1
                queue.name = "Kyooz.SearchHeaderExpandCollapseFunctionQueue"
                return queue
            }()
        }
        searchController.searchBar.resignFirstResponder()
        
        function.queue.addOperationWithBlock() {
            for group in self.groups {
                self.searchQueues[group]?.waitUntilAllOperationsAreFinished()
                self.completionQueue.waitUntilAllOperationsAreFinished()
            }
        }
        
        function.queue.addOperationWithBlock() {
            self.shouldReloadTableViewAfterSearchCompleted = false
            if let selectedHeader = self.selectedHeader {
                self.collapseSelectedSectionAndInsertSections(sender, selectedHeader: selectedHeader)
            } else {
                self.removeSectionsAndExpandSelectedSection(sender)
            }
            self.shouldReloadTableViewAfterSearchCompleted = true
        }
    }
    
    private func collapseSelectedSectionAndInsertSections(sender:UITapGestureRecognizer, selectedHeader:LibraryGrouping) {
        (sender.view as? SearchResultsHeaderView)?.animateDisclosureIndicator(shouldExpand:false)
        dispatch_sync(dispatch_get_main_queue()) {
            self.selectedHeader = nil
            
            guard let maxRows = self.maxRowsPerSection[selectedHeader], let currentNoOfRows = self.searchResults[selectedHeader]?.count else {
                return
            }
            
            //reduce the number of rows in the tableView to be equal to maxRows
            if maxRows < currentNoOfRows {
                var indexPaths = [NSIndexPath]()
                for i in maxRows..<currentNoOfRows {
                    indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
                }

                self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: indexPaths.count > 40 ? UITableViewRowAnimation.None : UITableViewRowAnimation.Automatic)
            }
        }
        
        updateSearchResults(self.searchController)
        
        for group in self.groups {
            searchQueues[group]?.waitUntilAllOperationsAreFinished()
            completionQueue.waitUntilAllOperationsAreFinished()
        }
        dispatch_sync(dispatch_get_main_queue()) {
            self.reloadSections()
            
            let indexSet = NSMutableIndexSet()
            for i in 0..<self.sections.count {
                if self.sections[i] !== selectedHeader {
                    indexSet.addIndex(i)
                }
            }
            
            if indexSet.count >= self.sections.count {
                let tempSections = self.sections
                self.sections.removeAll()
                self.tableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
                self.sections = tempSections
            }
            self.tableView.insertSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    private func removeSectionsAndExpandSelectedSection(sender:UITapGestureRecognizer) {
        for (group, gestureRecognizer) in self.tapGestureRecognizers {
            //here we check which header was tapped by matching it to the gesture recognizer instance we store and map to a grouping type
            if gestureRecognizer !== sender {
                continue
            }
            
            (sender.view as? SearchResultsHeaderView)?.animateDisclosureIndicator(shouldExpand:true)

            dispatch_sync(dispatch_get_main_queue()) {
                let indexSet = NSMutableIndexSet()
                
                for i in 0..<self.sections.count {
                    if group != self.sections[i] {
                        indexSet.addIndex(i)
                    }
                }
                self.sections = [group]
                self.tableView.deleteSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            
            self.selectedHeader = group
            //redo the search and wait for the results
            self.updateSearchResults(self.searchController)
            
            self.searchQueues[group]?.waitUntilAllOperationsAreFinished()
            self.completionQueue.waitUntilAllOperationsAreFinished()
            
            dispatch_sync(dispatch_get_main_queue()) {
                guard let searchResults = self.searchResults[group], let maxRows = self.maxRowsPerSection[group] else {
                    return
                }
                if searchResults.count > maxRows {
                    var indexPaths = [NSIndexPath]()
                    for i in maxRows..<searchResults.count {
                        indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
                    }
                    self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }
        }
        
    }
}
