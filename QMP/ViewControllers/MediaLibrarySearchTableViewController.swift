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

final class MediaLibrarySearchTableViewController : ParentMediaEntityViewController, UISearchResultsUpdating, UISearchBarDelegate, SearchExecutionControllerDelegate {


    static let instance = MediaLibrarySearchTableViewController()
    
    //MARK: - Properties
    var searchController:UISearchController!
    
    private let searchExecutionControllers:[SearchExecutionController<AudioEntity>] = {
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
    
    private let rowLimitPerSection = [LibraryGrouping.Albums:4, LibraryGrouping.Songs:6]
    
    
    private var sections = [SearchExecutionController<AudioEntity>]()
    private var tapGestureRecognizers = [LibraryGrouping:UITapGestureRecognizer]()
    private var selectedHeader:SearchExecutionController<AudioEntity>?
    
    private (set) var searchText:String!
    
    private var sourceData:AudioEntitySourceData!
    private var datasourceDelegate:AudioEntityDSDSectionDelegator! {
        didSet {
            tableView.dataSource = datasourceDelegate
            tableView.delegate = datasourceDelegate
        }
    }
    
    //MARK: - View life cycle
    override func viewDidLoad() {
        tableView = UITableView()
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        tableView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        tableView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        tableView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        
        super.viewDidLoad()
        tableView.registerNib(NibContainer.mediaCollectionTableViewCellNib, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
        tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
        tableView.registerClass(SearchHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SearchResultsHeaderView.reuseIdentifier)
        
        var datasourceDelegates = [AudioEntityDSDProtocol]()
        
        for searchExecutionController in searchExecutionControllers {
            searchExecutionController.delegate = self
            let sourceData = SearchResultsSourceData(searchExecutionController: searchExecutionController)
            let datasourceDelegate:AudioEntityDSDProtocol
            let reuseIdentifier = searchExecutionController.libraryGroup == LibraryGrouping.Albums ? ImageTableViewCell.reuseIdentifier : MediaCollectionTableViewCell.reuseIdentifier
            
            switch searchExecutionController.libraryGroup {
            case LibraryGrouping.Songs:
                datasourceDelegate = AudioTrackDSD(sourceData: sourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: nil)
            default:
                datasourceDelegate = AudioTrackCollectionDSD(sourceData:sourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: nil)
            }
            
            datasourceDelegates.append(datasourceDelegate)
        }
        let sectionDelegator = AudioEntityDSDSectionDelegator(datasources: datasourceDelegates)
        sourceData = sectionDelegator
        datasourceDelegate = sectionDelegator
        
        
        popGestureRecognizer.enabled = false
    }
    
    
    //MARK: header configuration
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section >= sections.count {
            Logger.error("section index received is greater than the number of sections avaliable")
            return nil
        }
        let searchExecutor = sections[section]
        let group = searchExecutor.libraryGroup
        guard let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SearchResultsHeaderView.reuseIdentifier) as? SearchHeaderFooterView else {
            return nil
        }
        view.initializeHeaderView()
        
        guard let headerView = view.headerView else {
            return nil
        }
        headerView.headerTitleLabel.text = group.name.uppercaseString
        if sections.count > 1 || selectedHeader != nil {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "didTapHeaderView:")
            headerView.addGestureRecognizer(tapGestureRecognizer)
            headerView.disclosureContainerView.hidden = false
            tapGestureRecognizers[group] = tapGestureRecognizer
        } else {
            headerView.disclosureContainerView.hidden = true
        }
        
        headerView.applyRotation(shouldExpand: selectedHeader != nil && searchExecutor === selectedHeader!)
        
        return headerView
    }
    
    //MARK: other configuration
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section >= sections.count || indexPath.row >= sections[indexPath.section].searchResults.count {
            Logger.error("indexPath received is greater than the number of sections or search results avaliable")
            return
        }
        
        let searchExecutor = sections[indexPath.section]
        let entity = searchExecutor.searchResults[indexPath.row]
        let group = searchExecutor.libraryGroup
        
        if let item = entity as? MPMediaItem where group === LibraryGrouping.Songs {
            audioQueuePlayer.playNow(withTracks: [item], startingAtIndex: 0, shouldShuffleIfOff: false)
            return
        }
        
        (presentingViewController as? UINavigationController)?.popToRootViewControllerAnimated(false)
		
		if let audioEntity = entity as? AudioTrackCollection, let sourceData = MediaQuerySourceData(filterEntity: audioEntity, parentLibraryGroup: group, baseQuery: nil) {
			ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(sourceData, parentGroup: group, entity: audioEntity)
		}
		
        //doing this asynchronously because it must be effective after the previous animations have taken place
        KyoozUtils.doInMainQueueAsync() {
            RootViewController.instance.previousSearchText = self.searchText
        }
    }
    //MARK: - SCROLL DELEGATE
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
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
        var newSections = [SearchExecutionController<AudioEntity>]()
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
    
    private func collapseSelectedSectionAndInsertSections(sender:UITapGestureRecognizer, selectedHeader:SearchExecutionController<AudioEntity>) {
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
    
    private func removeSectionsAndExpandSelectedSection(sender:UITapGestureRecognizer, searchExecutor:SearchExecutionController<AudioEntity>) {
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
