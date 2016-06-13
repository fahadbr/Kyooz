//
//  AudioEntitySearchViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/8/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class AudioEntitySearchViewController : AudioEntityHeaderViewController, UISearchBarDelegate, DragSource, SearchExecutionControllerDelegate, RowLimitedSectionDelegatorDelegate {

    static let instance = AudioEntitySearchViewController()
    
    var isExpanded = false {
        didSet {
            if isExpanded {
                searchBar.becomeFirstResponder()
                textField?.selectAll(nil)
            } else {
                searchBar.resignFirstResponder()
                if tableView.editing {
                    toggleSelectMode()
                }
                KyoozUtils.doInMainQueueAfterDelay(0.4) {
                    (self.datasourceDelegate as? RowLimitedSectionDelegator)?.collapseAllSections()
                    self.reloadTableViewData()
                }
            }
            tableView.scrollsToTop = isExpanded
        }
    }
    
    var sourceTableView: UITableView? {
        return tableView
    }
    
    private lazy var textField:UITextField? = {
        for subView in self.searchBar.subviews {
            if subView.subviews.count < 2 { continue }
            if let textField = subView.subviews[1] as? UITextField {
                return textField
            }
        }
        return nil
    }()
	
    lazy var shortNotificationManager = ShortNotificationManager.instance
    
    //MARK: - Properties
    lazy var searchExecutionControllers:[SearchExecutionController] = {
        let artistSearchExecutor = IPodLibrarySearchExecutionController(libraryGroup: LibraryGrouping.Artists,
            searchKeys: [MPMediaItemPropertyAlbumArtist])
        let albumSearchExecutor = IPodLibrarySearchExecutionController(libraryGroup: LibraryGrouping.Albums,
            searchKeys: [MPMediaItemPropertyAlbumTitle, MPMediaItemPropertyAlbumArtist])
        let songSearchExecutor = IPodLibrarySearchExecutionController(libraryGroup: LibraryGrouping.Songs,
            searchKeys: [MPMediaItemPropertyTitle, MPMediaItemPropertyAlbumTitle, MPMediaItemPropertyAlbumArtist])
        let playlistSearchExecutor = IPodLibrarySearchExecutionController(libraryGroup: LibraryGrouping.Playlists,
            searchKeys: [MPMediaPlaylistPropertyName])
        let audioBooksSearchExecutor = IPodLibrarySearchExecutionController(libraryGroup: LibraryGrouping.AudioBooks, searchKeys: [MPMediaItemPropertyTitle])
        let compilationsSearchExecutor = IPodLibrarySearchExecutionController(libraryGroup: LibraryGrouping.Compilations, searchKeys: [MPMediaItemPropertyAlbumTitle])
        let podcastSearchExecutor = IPodLibrarySearchExecutionController(libraryGroup: LibraryGrouping.Podcasts,
                                                                         searchKeys: [MPMediaItemPropertyPodcastTitle, MPMediaItemPropertyAlbumArtist])
        let kyoozPlaylistSearchExecutor = KyoozPlaylistSearchExecutionController()
        return [artistSearchExecutor, albumSearchExecutor, kyoozPlaylistSearchExecutor, playlistSearchExecutor, compilationsSearchExecutor, songSearchExecutor, podcastSearchExecutor, audioBooksSearchExecutor]
    }()
    
    private let defaultRowLimit = 3
    private let rowLimitPerSection = [LibraryGrouping.Albums:4, LibraryGrouping.Songs:6]
	
    private (set) var searchText:String!
    
    private let searchBar = UISearchBar()
    private let activityIndicator = UIActivityIndicatorView()
    private let tableFooterView = KyoozTableFooterView()
	
    //MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.searchBarStyle = UISearchBarStyle.Minimal
        searchBar.sizeToFit()
        searchBar.barStyle = UIBarStyle.Black
        searchBar.translucent = false
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        searchBar.tintColor = ThemeHelper.defaultVividColor
        searchBar.backgroundColor = UIColor.clearColor()
        navigationItem.titleView = searchBar
        
		
        tableView.scrollsToTop = isExpanded
        tableView.rowHeight = ThemeHelper.sidePanelTableViewRowHeight
        
        activityIndicator.color = ThemeHelper.defaultVividColor
        applyDatasourceDelegate()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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
            if let rowLimitedDSD = self.datasourceDelegate as? RowLimitedSectionDelegator {
                rowLimitedDSD.reloadSections()
                self.reloadTableFooter(rowLimitedDSD)
            }
            super.reloadTableViewData()
        }
    }
    
    func getSourceData() -> AudioEntitySourceData? {
        searchBar.resignFirstResponder()
        return sourceData
    }
    
    func applyDatasourceDelegate() {
        var datasourceDelegatesWithRowLimit = [(AudioEntityDSDProtocol, Int)]()
        for searchExecutionController in searchExecutionControllers {
            searchExecutionController.delegate = self
            let libraryGroup = searchExecutionController.libraryGroup
            let sourceData = SearchResultsSourceData(searchExecutionController: searchExecutionController)
            let datasourceDelegate:AudioEntityDSD
            let reuseIdentifier = libraryGroup.usesArtwork ? ImageTableViewCell.reuseIdentifier : MediaCollectionTableViewCell.reuseIdentifier
            
            switch libraryGroup {
            case LibraryGrouping.Songs:
                let audioTrackDSD = AudioTrackDSD(sourceData: sourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: self)
                audioTrackDSD.playAllTracksOnSelection = false
                datasourceDelegate = audioTrackDSD
            default:
                datasourceDelegate = AudioTrackCollectionDSD(sourceData:sourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: self)
            }
            datasourceDelegate.useSmallFont = true
            datasourceDelegatesWithRowLimit.append((datasourceDelegate, rowLimitPerSection[libraryGroup] ?? defaultRowLimit))
        }
        let sectionDelegator = RowLimitedSectionDelegator(datasourcesWithRowLimits: datasourceDelegatesWithRowLimit, tableView: tableView)
        sectionDelegator.delegate = self
        sourceData = sectionDelegator
        datasourceDelegate = sectionDelegator

    }
    
    
    private func reloadTableFooter(rowLimitedDSD:RowLimitedSectionDelegator) {
        var count = 0
        rowLimitedDSD.dsdSections.forEach() {
            count += $0.sourceData.entities.count
        }
        
        var groupName = rowLimitedDSD.dsdSections.count != 1 ? "RESULTS" : rowLimitedDSD.dsdSections[0].sourceData.libraryGrouping.name
        groupName = count == 1 ? groupName.withoutLast() : groupName
        
        self.tableFooterView.text = "\(count) \(groupName)"
        self.tableView.tableFooterView = self.tableFooterView

    }

    override func createHeaderView() -> HeaderViewController {
        let vc = GenericWrapperViewController(viewToWrap: activityIndicator)
        return UtilHeaderViewController(centerViewController:vc)
    }
    
    override func addCustomMenuActions(indexPath:NSIndexPath, tracks:[AudioTrack], menuController:KyoozMenuViewController) {
        searchBar.resignFirstResponder()
        super.addCustomMenuActions(indexPath, tracks:tracks, menuController: menuController)
        guard let mediaItem = tracks.first where tracks.count == 1 else { return }
        var actions = [KyoozMenuActionProtocol]()
        if mediaItem.albumId != 0 {
            let goToAlbumAction = KyoozMenuAction(title: KyoozConstants.JUMP_TO_ALBUM, image: nil) {
                ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(MediaQuerySourceData(filterEntity: mediaItem, parentLibraryGroup: LibraryGrouping.Albums, baseQuery: nil)!, parentGroup: LibraryGrouping.Albums, entity: mediaItem)
            }
            actions.append(goToAlbumAction)
        }
        
        if mediaItem.albumArtistId != 0 {
            let goToArtistAction = KyoozMenuAction(title: KyoozConstants.JUMP_TO_ARTIST, image: nil) {
                ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(MediaQuerySourceData(filterEntity: mediaItem, parentLibraryGroup: LibraryGrouping.Artists, baseQuery: nil)!, parentGroup: LibraryGrouping.Artists, entity: mediaItem)
            }
            actions.append(goToArtistAction)
        }
        menuController.addActions(actions)
    }

    
    //MARK: - Search Bar Delegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        defer {
            refreshActivityView()
        }
		guard !searchText.isEmpty else { return }
		
		let normalizedSearchText = searchText.normalizedString
		guard (self.searchText ?? "") != normalizedSearchText else {
			return
		}
		
		self.searchText = normalizedSearchText
		let searchStringComponents = normalizedSearchText.componentsSeparatedByString(" ")
		
		for searchExecutor in searchExecutionControllers {
			searchExecutor.executeSearchForStringComponents(normalizedSearchText, stringComponents: searchStringComponents)
		}
    }
    
    
    //MARK: - SearchExecutionController Delegate
    func searchResultsDidGetUpdated() {
        if tableView.editing {
            toggleSelectMode()
        }
        reloadTableViewData()
    }
    
    func searchDidComplete() {
        KyoozUtils.doInMainQueue(refreshActivityView)
    }
    
    func refreshActivityView() {
        var searchInProgress = false
        for se in searchExecutionControllers {
            if se.searchInProgress {
                searchInProgress = true
                break
            }
        }
        if searchInProgress && !activityIndicator.isAnimating() {
            activityIndicator.startAnimating()
        } else if !searchInProgress && activityIndicator.isAnimating() {
            activityIndicator.stopAnimating()
        }
    }
    
    func initializeIndicies() {
        Logger.debug("Search Index Rebuild has been triggered")
        indexQueue.cancelAllOperations()
        searchExecutionControllers.forEach() { $0.rebuildSearchIndex() }
    }
    
    func willExpandOrCollapseSection() {
        searchBar.resignFirstResponder()
    }
    
    func didExpandOrCollapseSection() {
        if let rowLimitedDSD = datasourceDelegate as? RowLimitedSectionDelegator {
            reloadTableFooter(rowLimitedDSD)
        }
    }
    
}

//MARK: - MultiSelect overrides
extension AudioEntitySearchViewController {
    override func toggleSelectMode() {
        super.toggleSelectMode()
        searchBar.resignFirstResponder()
    }
    
    override func selectOrDeselectAll() {
        let willSelectAll = tableView.indexPathsForSelectedRows == nil
        if let rowLimitedDSD = datasourceDelegate as? RowLimitedSectionDelegator
            where rowLimitedDSD.sections.count > 1 && willSelectAll {
            shortNotificationManager.presentShortNotification(withMessage: "Tip: Expand a search results section to select all the results for that particular section")
        }
        super.selectOrDeselectAll()
    }
    
}
