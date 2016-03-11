//
//  AudioEntitySearchViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/8/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class AudioEntitySearchViewController : AudioEntityViewController, UISearchResultsUpdating, UISearchBarDelegate, SearchExecutionControllerDelegate, RowLimitedSectionDelegatorDelegate {

    static let instance = AudioEntitySearchViewController()
    
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
    
    private let defaultRowLimit = 3
    private let rowLimitPerSection = [LibraryGrouping.Albums:4, LibraryGrouping.Songs:6]
	
    private (set) var searchText:String!
	
    
    //MARK: - View life cycle
    override func viewDidLoad() {
        tableView = UITableView()
		ConstraintUtils.applyStandardConstraintsToView(subView: tableView, parentView: view)
        
        super.viewDidLoad()
        tableView.registerNib(NibContainer.mediaCollectionTableViewCellNib, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
        tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
        tableView.registerClass(SearchHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SearchResultsHeaderView.reuseIdentifier)
        
        var datasourceDelegatesWithRowLimit = [(AudioEntityDSDProtocol, Int)]()
        
        for searchExecutionController in searchExecutionControllers {
            searchExecutionController.delegate = self
            let libraryGroup = searchExecutionController.libraryGroup
            let sourceData = SearchResultsSourceData(searchExecutionController: searchExecutionController)
            let datasourceDelegate:AudioEntityDSDProtocol
            let reuseIdentifier = libraryGroup == LibraryGrouping.Albums ? ImageTableViewCell.reuseIdentifier : MediaCollectionTableViewCell.reuseIdentifier
            
            switch libraryGroup {
            case LibraryGrouping.Songs:
                let audioTrackDSD = AudioTrackDSD(sourceData: sourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: self)
                audioTrackDSD.playAllTracksOnSelection = false
                datasourceDelegate = audioTrackDSD
            default:
                datasourceDelegate = AudioTrackCollectionDSD(sourceData:sourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: self)
            }
            
            datasourceDelegatesWithRowLimit.append((datasourceDelegate, rowLimitPerSection[libraryGroup] ?? defaultRowLimit))
        }
        let sectionDelegator = RowLimitedSectionDelegator(datasourcesWithRowLimits: datasourceDelegatesWithRowLimit, tableView: tableView)
		sectionDelegator.delegate = self
        sourceData = sectionDelegator
		datasourceDelegate = sectionDelegator

        popGestureRecognizer.enabled = false
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
            (self.datasourceDelegate as? RowLimitedSectionDelegator)?.reloadSections()
            super.reloadTableViewData()
        }
    }
    
    override func getMediaItemsForIndexPath(indexPath: NSIndexPath) -> [AudioTrack] {
        searchController.searchBar.resignFirstResponder()
        return sourceData.getTracksAtIndex(indexPath)
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
                searchExecutor.executeSearchForStringComponents(text, stringComponents: searchStringComponents)
            }
        } else {
            (datasourceDelegate as? RowLimitedSectionDelegator)?.collapseAllSections()
        }
    }
    
    //MARK: - SearchExecutionController Delegate
    func searchResultsDidGetUpdated() {
        reloadTableViewData()
    }
    
    func initializeIndicies() {
        Logger.debug("Search Index Rebuild has been triggered")
        indexQueue.cancelAllOperations()
        searchExecutionControllers.forEach() { $0.rebuildSearchIndex() }
    }
    
    func willExpandOrCollapseSection() {
        searchController.searchBar.resignFirstResponder()
    }
    
}
