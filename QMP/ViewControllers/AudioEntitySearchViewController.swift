//
//  AudioEntitySearchViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/8/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class AudioEntitySearchViewController : AudioEntityViewController, UISearchBarDelegate, DragSource, SearchExecutionControllerDelegate, RowLimitedSectionDelegatorDelegate {

    static let instance = AudioEntitySearchViewController()
    
    var isExpanded = false {
        didSet {
            if isExpanded {
                searchBar.becomeFirstResponder()
                textField?.selectAll(nil)
            } else {
                searchBar.resignFirstResponder()
				(datasourceDelegate as? RowLimitedSectionDelegator)?.collapseAllSections()
				reloadTableViewData()
            }
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
        let kyoozPlaylistSearchExecutor = KyoozPlaylistSearchExecutionController()
        return [artistSearchExecutor, albumSearchExecutor, songSearchExecutor, kyoozPlaylistSearchExecutor, playlistSearchExecutor]
    }()
    
    private let defaultRowLimit = 3
    private let rowLimitPerSection = [LibraryGrouping.Albums:4, LibraryGrouping.Songs:6]
	
    private (set) var searchText:String!
    
    private let searchBar = UISearchBar()
	
    
    //MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.searchBarStyle = UISearchBarStyle.Default
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.barStyle = UIBarStyle.Black
        searchBar.translucent = false
        searchBar.placeholder = "Library Search"
        searchBar.searchFieldBackgroundPositionAdjustment = UIOffset(horizontal: 0, vertical: 10)
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Left, .Top, .Right], subView: searchBar, parentView: view)
        let height:CGFloat = 65
        searchBar.heightAnchor.constraintEqualToConstant(height).active = true
        
        tableView.contentInset.top = height
        tableView.scrollIndicatorInsets.top = height
        tableView.rowHeight = 48
        tableView.registerNib(NibContainer.mediaCollectionTableViewCellNib, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
        tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
        tableView.registerClass(SearchHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SearchResultsHeaderView.reuseIdentifier)
        
        var datasourceDelegatesWithRowLimit = [(AudioEntityDSDProtocol, Int)]()
        let overrideFont = UIFont(name: ThemeHelper.defaultFontNameBold, size: 12)
        for searchExecutionController in searchExecutionControllers {
            searchExecutionController.delegate = self
            let libraryGroup = searchExecutionController.libraryGroup
            let sourceData = SearchResultsSourceData(searchExecutionController: searchExecutionController)
            let datasourceDelegate:AudioEntityDSD
            let reuseIdentifier = libraryGroup == LibraryGrouping.Albums ? ImageTableViewCell.reuseIdentifier : MediaCollectionTableViewCell.reuseIdentifier
            
            switch libraryGroup {
            case LibraryGrouping.Songs:
                let audioTrackDSD = AudioTrackDSD(sourceData: sourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: self)
                audioTrackDSD.playAllTracksOnSelection = false
                datasourceDelegate = audioTrackDSD
            default:
                datasourceDelegate = AudioTrackCollectionDSD(sourceData:sourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: self)
            }
            datasourceDelegate.titleFontOverride = overrideFont
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
        if mediaItem.albumId != 0 {
            let goToAlbumAction = KyoozMenuAction(title: "Jump To Album", image: nil) {
                ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(MediaQuerySourceData(filterEntity: mediaItem, parentLibraryGroup: LibraryGrouping.Albums, baseQuery: nil)!, parentGroup: LibraryGrouping.Albums, entity: mediaItem)
            }
            menuController.addAction(goToAlbumAction)
        }
        
        if mediaItem.albumArtistId != 0 {
            let goToArtistAction = KyoozMenuAction(title: "Jump To Artist", image: nil) {
                ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(MediaQuerySourceData(filterEntity: mediaItem, parentLibraryGroup: LibraryGrouping.Artists, baseQuery: nil)!, parentGroup: LibraryGrouping.Artists, entity: mediaItem)
            }
            menuController.addAction(goToArtistAction)
        }
    }

    
    //MARK: - Search Bar Delegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		guard !searchText.isEmpty else { return }
		
		let normalizedSearchText = searchText.normalizedString
		if let currentText = self.searchText where currentText == normalizedSearchText {
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
    
    func initializeIndicies() {
        Logger.debug("Search Index Rebuild has been triggered")
        indexQueue.cancelAllOperations()
        searchExecutionControllers.forEach() { $0.rebuildSearchIndex() }
    }
    
    func willExpandOrCollapseSection() {
        searchBar.resignFirstResponder()
    }
    
}
