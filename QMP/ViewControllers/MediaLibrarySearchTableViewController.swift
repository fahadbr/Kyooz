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

class MediaLibrarySearchTableViewController : AbstractMediaEntityTableViewController, UISearchResultsUpdating, UISearchBarDelegate, SearchExecutionControllerDelegate {
    
    private class RowLimit {
        let limit:Int
        var isExpanded:Bool = false
        init(limit:Int) {
            self.limit = limit
        }
    }


    static let instance = MediaLibrarySearchTableViewController()
    
    //MARK: - Properties
    var searchController:UISearchController!
    
    private let searchExecutionControllers:[SearchExecutionController<MPMediaEntity>] = {
        let artistSearchExecutor = IPodLibrarySearchExecutionController(libraryGroup: LibraryGrouping.Artists,
            searchKeys: [MPMediaItemPropertyAlbumArtist])
        let albumSearchExecutor = IPodLibrarySearchExecutionController(libraryGroup: LibraryGrouping.Albums,
            searchKeys: [MPMediaItemPropertyAlbumTitle, MPMediaItemPropertyAlbumArtist])
        let songSearchExecutor = IPodLibrarySearchExecutionController(libraryGroup: LibraryGrouping.Songs,
            searchKeys: [MPMediaItemPropertyTitle, MPMediaItemPropertyAlbumTitle, MPMediaItemPropertyAlbumArtist])
        let playlistSearchExecutor = IPodLibrarySearchExecutionController(libraryGroup: LibraryGrouping.Playlists,
            searchKeys: [MPMediaPlaylistPropertyName])
        return [artistSearchExecutor, albumSearchExecutor, songSearchExecutor, playlistSearchExecutor]
    }()
    
    private let rowLimitPerSection = [LibraryGrouping.Artists:RowLimit(limit: 3),
        LibraryGrouping.Albums:RowLimit(limit: 4),
        LibraryGrouping.Songs:RowLimit(limit: 6),
        LibraryGrouping.Playlists:RowLimit(limit: 3)]
    
    
    private var sections = [SearchExecutionController<MPMediaEntity>]()
    private var tapGestureRecognizers = [LibraryGrouping:UITapGestureRecognizer]()
    private var selectedHeader:SearchExecutionController<MPMediaEntity>?
    
    private (set) var searchText:String!
    
    //MARK: - View life cycle
    override func viewDidLoad() {
        for se in searchExecutionControllers {
            se.delegate = self
        }
        
        super.viewDidLoad()
        tableView.registerClass(MediaCollectionTableViewCell.self, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
        tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
    }
    
    //MARK: - Table View Datasource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }

    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section >= sections.count {
            Logger.error("section index received is greater than the number of sections avaliable")
            return 0
        }
        let searchExecutor = sections[section]
        let rowLimit = rowLimitPerSection[searchExecutor.libraryGroup]!
        
        if rowLimit.isExpanded {
            return searchExecutor.searchResults.count
        }
        
        return rowLimit.limit < searchExecutor.searchResults.count ? rowLimit.limit : searchExecutor.searchResults.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let searchExecutor = sections[indexPath.section]
        let group = searchExecutor.libraryGroup
        let reuseIdentifier = group === LibraryGrouping.Albums ? ImageTableViewCell.reuseIdentifier : MediaCollectionTableViewCell.reuseIdentifier
        
        guard let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) else {
            return UITableViewCell()
        }
        
        guard indexPath.row < searchExecutor.searchResults.count else {
            return UITableViewCell()
        }
        let entity = searchExecutor.searchResults[indexPath.row]
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
        if section >= sections.count {
            Logger.error("section index received is greater than the number of sections avaliable")
            return nil
        }
        let searchExecutor = sections[section]
        let group = searchExecutor.libraryGroup
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
        
        view.applyRotation(shouldExpand: selectedHeader != nil && searchExecutor === selectedHeader!)
        
        return view
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
    
    //MARK: other configuration
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section >= sections.count || indexPath.row >= sections[indexPath.section].searchResults.count {
            Logger.error("indexPath received is greater than the number of sections or search results avaliable")
            return
        }
        
        let searchExecutor = sections[indexPath.section]
        let entity = searchExecutor.searchResults[indexPath.row]
        let group = searchExecutor.libraryGroup
        
        if let item = entity as? MPMediaItem where group === LibraryGrouping.Songs {
            audioQueuePlayer.playNow(withTracks: [item], startingAtIndex: 0)
            return
        }
        
        (presentingViewController as? UINavigationController)?.popToRootViewControllerAnimated(false)
        
        ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(basePredicates: group.nextGroupLevel!.baseQuery.filterPredicates, parentGroup: group, entity: entity)
        
        //doing this asynchronously because it must be effective after the previous animations have taken place
        KyoozUtils.doInMainQueueAsync() {
            RootViewController.instance.previousSearchText = self.searchText
        }
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
        KyoozUtils.doInMainQueue() {
            self.reloadSections()
            super.reloadTableViewData()
        }
    }
    
    override func getMediaItemsForIndexPath(indexPath: NSIndexPath) -> [AudioTrack] {
        if indexPath.section >= sections.count {
            Logger.error("section index received is greater than the number of sections avaliable")
            return [AudioTrack]()
        }
        
        searchController.searchBar.resignFirstResponder()
        let searchExecutor = sections[indexPath.section]
        if searchExecutor.searchResults.count <= indexPath.row {
            Logger.error("index received is greater than the number of search results avaliable")
            return [AudioTrack]()
        }
        
        let entity = searchExecutor.searchResults[indexPath.row]
        
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
    
    
    //MARK: - Search Results Updating
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let text = searchController.searchBar.text?.normalizedString where !text.isEmpty {
            if let currentText = self.searchText where currentText == text {
                return
            }
            
            searchText = text
            let searchStringComponents = text.componentsSeparatedByString(" ") as [String]
            
            for searchExecutor in searchExecutionControllers {
                searchExecutor.clearSearchResults()
                
                searchExecutor.executeSearchForStringComponents(text, stringComponents: searchStringComponents)
            }
        } else {
            selectedHeader = nil
        }
    }
    
    //MARK: - SearchExecutionController Delegate
    func searchResultsDidGetUpdated() {
        reloadTableViewData()
    }
    
    func initializeIndicies() {
        Logger.debug("Search Index Rebuild has been triggered")
        indexQueue.cancelAllOperations()
        for searchExecutor in searchExecutionControllers {
            searchExecutor.rebuildSearchIndex()
        }
    }
    
    private func reloadSections() {
        var newSections = [SearchExecutionController<MPMediaEntity>]()
        if let selectedHeader = self.selectedHeader {
            newSections = [selectedHeader]
        } else {
            for searchExecutor in searchExecutionControllers {
                if !searchExecutor.searchResults.isEmpty {
                    newSections.append(searchExecutor)
                }
                rowLimitPerSection[searchExecutor.libraryGroup]?.isExpanded = false
            }
            if newSections.count == 1 {
                rowLimitPerSection[newSections[0].libraryGroup]?.isExpanded = true
            }
        }
        sections = newSections
    }
    
    //MARK: tap gesture handler
    func didTapHeaderView(sender:UITapGestureRecognizer) {
        searchController.searchBar.resignFirstResponder()
        
        if let se = self.selectedHeader {
            self.collapseSelectedSectionAndInsertSections(sender, selectedHeader: se)
        } else if let se = searchExecutionControllers.filter({ self.tapGestureRecognizers[$0.libraryGroup] === sender }).first {
            self.removeSectionsAndExpandSelectedSection(sender, searchExecutor: se)
        }
    }
    
    private func collapseSelectedSectionAndInsertSections(sender:UITapGestureRecognizer, selectedHeader:SearchExecutionController<MPMediaEntity>) {
        (sender.view as? SearchResultsHeaderView)?.animateDisclosureIndicator(shouldExpand:false)
        self.selectedHeader = nil
        
        let rowLimit = rowLimitPerSection[selectedHeader.libraryGroup]!
        let maxRows = rowLimit.limit
        rowLimit.isExpanded = false
        
        let currentNoOfRows = selectedHeader.searchResults.count
        var reloadAllSections = false
        //reduce the number of rows in the tableView to be equal to maxRows
        if maxRows < currentNoOfRows {
            if currentNoOfRows > 300 {
                reloadAllSections = true
            } else {
                var indexPaths = [NSIndexPath]()
                for i in maxRows..<currentNoOfRows {
                    indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
                }

                self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
            }
        }
        
        self.reloadSections()
        
        let indexSet = NSMutableIndexSet()
        for i in 0..<self.sections.count {
            if self.sections[i] !== selectedHeader || reloadAllSections {
                indexSet.addIndex(i)
            }
        }
        
        tableView.beginUpdates()
        if indexSet.count >= self.sections.count {
            self.tableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
        }
        tableView.insertSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic)
        tableView.endUpdates()
    }
    
    private func removeSectionsAndExpandSelectedSection(sender:UITapGestureRecognizer, searchExecutor:SearchExecutionController<MPMediaEntity>) {
        (sender.view as? SearchResultsHeaderView)?.animateDisclosureIndicator(shouldExpand:true)

        let indexSet = NSMutableIndexSet()
        
        for i in 0..<self.sections.count {
            if searchExecutor !== self.sections[i] {
                indexSet.addIndex(i)
            }
        }
        self.sections = [searchExecutor]
        self.tableView.deleteSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic)
        
        self.selectedHeader = searchExecutor
        
        let searchResults = searchExecutor.searchResults
        let rowLimit = rowLimitPerSection[searchExecutor.libraryGroup]!
        
        rowLimit.isExpanded = true
        let maxRows = rowLimit.limit
        
        if searchResults.count > maxRows {
            var indexPaths = [NSIndexPath]()
            for i in maxRows..<searchResults.count {
                indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
            }
            self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
}
