//
//  AudioEntitySearchViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/8/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class AudioEntitySearchViewController : AudioEntityPlainHeaderViewController, UISearchBarDelegate, DragSource, SearchExecutionControllerDelegate, RowLimitedSectionDelegatorDelegate {

    static let instance = AudioEntitySearchViewController()
    
    var isExpanded = false {
        didSet {
            if isExpanded {
                searchBar.becomeFirstResponder()
                textField?.selectAll(nil)
            } else {
                searchBar.resignFirstResponder()
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
	
	
    
    //MARK: - Properties
    private let searchExecutionControllers:[SearchExecutionController] = {
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
	
    //MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        headerView.userInteractionEnabled = true
        searchBar.searchBarStyle = UISearchBarStyle.Minimal
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.barStyle = UIBarStyle.Black
        searchBar.translucent = false
        searchBar.placeholder = "Search"
        searchBar.tintColor = ThemeHelper.defaultVividColor
        searchBar.searchFieldBackgroundPositionAdjustment = UIOffset(horizontal: 0, vertical: 10)
		searchBar.backgroundColor = UIColor.clearColor()
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Left, .Top, .Bottom], subView: searchBar, parentView: headerView.contentView)
        
		
        tableView.scrollsToTop = isExpanded
        tableView.rowHeight = ThemeHelper.sidePanelTableViewRowHeight
        
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Bottom, .Right], subView: activityIndicator, parentView: headerView.contentView).forEach() {
            $1.constant = -8
        }
        activityIndicator.color = ThemeHelper.defaultVividColor
        activityIndicator.widthAnchor.constraintEqualToConstant(30).active = true
        activityIndicator.heightAnchor.constraintEqualToAnchor(activityIndicator.widthAnchor).active = true
        activityIndicator.leftAnchor.constraintEqualToAnchor(searchBar.rightAnchor).active = true
        
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
            datasourceDelegate.shouldAnimateCell = false
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
    
    func getSourceData() -> AudioEntitySourceData? {
        searchBar.resignFirstResponder()
        return sourceData
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
		let searchStringComponents = normalizedSearchText.componentsSeparatedByString(" ") as [String]
		
		for searchExecutor in searchExecutionControllers {
			searchExecutor.executeSearchForStringComponents(normalizedSearchText, stringComponents: searchStringComponents)
		}
    }
    
    
    //MARK: - SearchExecutionController Delegate
    func searchResultsDidGetUpdated() {
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
    
}