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
    
    override class var shouldAnimateInArtworkDefault: Bool {
        return false
    }
    
    var isExpanded = false {
        didSet {
            if isExpanded {
                searchBar.becomeFirstResponder()
                textField?.selectAll(nil)
            } else {
                searchBar.resignFirstResponder()
                if tableView.isEditing {
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
    
    fileprivate lazy var textField:UITextField? = {
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
        
        let audioBooksSearchExecutor = IPodLibrarySearchExecutionController(libraryGroup: LibraryGrouping.AudioBooks,
                                                                            searchKeys: [MPMediaItemPropertyTitle])
        
        let compilationsSearchExecutor = IPodLibrarySearchExecutionController(libraryGroup: LibraryGrouping.Compilations,
                                                                              searchKeys: [MPMediaItemPropertyAlbumTitle])
        
        let podcastSearchExecutor = IPodLibrarySearchExecutionController(libraryGroup: LibraryGrouping.Podcasts,
                                                                         searchKeys: [MPMediaItemPropertyPodcastTitle, MPMediaItemPropertyAlbumArtist])
        
        let kyoozPlaylistSearchExecutor = KyoozPlaylistSearchExecutionController()
        
        return [artistSearchExecutor, albumSearchExecutor, kyoozPlaylistSearchExecutor, playlistSearchExecutor, compilationsSearchExecutor, songSearchExecutor, podcastSearchExecutor, audioBooksSearchExecutor]
    }()
    
    fileprivate let defaultRowLimit = 3
    fileprivate let rowLimitPerSection = [LibraryGrouping.Albums:4, LibraryGrouping.Songs:6]
	
    fileprivate (set) var searchText:String!
    
    fileprivate let searchBar = UISearchBar()
    fileprivate let tableFooterView = KyoozTableFooterView()
	
    //MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(RowLimitedSectionHeaderView.self,
                                forHeaderFooterViewReuseIdentifier: RowLimitedSectionHeaderView.reuseIdentifier)
        
        searchBar.searchBarStyle = UISearchBarStyle.minimal
        searchBar.sizeToFit()
        searchBar.barStyle = UIBarStyle.black
        searchBar.isTranslucent = false
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        searchBar.tintColor = ThemeHelper.defaultVividColor
        searchBar.backgroundColor = UIColor.clear
        searchBar.accessibilityLabel = "Search"
        
        headerHeightConstraint.constant = ThemeHelper.plainHeaderHight
        tableView.scrollIndicatorInsets.top = ThemeHelper.plainHeaderHight
        tableView.contentInset.top = ThemeHelper.plainHeaderHight
        navigationController?.navigationBar.isUserInteractionEnabled = false
		
        tableView.scrollsToTop = isExpanded
        tableView.rowHeight = ThemeHelper.sidePanelTableViewRowHeight
        
        applyDatasourceDelegate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        popGestureRecognizer.isEnabled = false
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
        var dsds = [AudioEntityDSDProtocol]()
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
            datasourceDelegate.rowLimit = rowLimitPerSection[libraryGroup] ?? defaultRowLimit
            datasourceDelegate.rowLimitActive = true
            dsds.append(datasourceDelegate)
        }
        let sectionDelegator = RowLimitedSectionDelegator(datasourceDelegates: dsds, tableView: tableView)
        sectionDelegator.delegate = self
        sourceData = sectionDelegator
        datasourceDelegate = sectionDelegator

    }
    
    
    fileprivate func reloadTableFooter(_ rowLimitedDSD:RowLimitedSectionDelegator) {
        let count = rowLimitedDSD.dsdSections.reduce(0) {
            return $0 + $1.sourceData.entities.count
        }
        
        var groupName = rowLimitedDSD.dsdSections.count != 1 ? "RESULTS" : rowLimitedDSD.dsdSections[0].sourceData.libraryGrouping.name
        groupName = count == 1 ? groupName.withoutLast() : groupName
        
        self.tableFooterView.text = "\(count) \(groupName)"
        self.tableView.tableFooterView = self.tableFooterView

    }

    override func createHeaderView() -> HeaderViewController {
        let vc = GenericWrapperViewController(viewToWrap: searchBar)
        return UtilHeaderViewController(centerViewController:vc)
    }
    
	override func addCustomMenuActions(_ indexPath:IndexPath, tracks:[AudioTrack], menuBuilder:MenuBuilder) {
        searchBar.resignFirstResponder()
        super.addCustomMenuActions(indexPath, tracks:tracks, menuBuilder: menuBuilder)
        guard let mediaItem = tracks.first , tracks.count == 1 else { return }
        var actions = [KyoozOption]()
        if mediaItem.albumId != 0 {
            let goToAlbumAction = KyoozMenuAction(title: KyoozConstants.JUMP_TO_ALBUM) {
                ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(MediaQuerySourceData(filterEntity: mediaItem, parentLibraryGroup: LibraryGrouping.Albums, baseQuery: nil)!, parentGroup: LibraryGrouping.Albums, entity: mediaItem)
            }
            actions.append(goToAlbumAction)
        }
        
        if mediaItem.albumArtistId != 0 {
            let goToArtistAction = KyoozMenuAction(title: KyoozConstants.JUMP_TO_ARTIST) {
                ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(MediaQuerySourceData(filterEntity: mediaItem, parentLibraryGroup: LibraryGrouping.Artists, baseQuery: nil)!, parentGroup: LibraryGrouping.Artists, entity: mediaItem)
            }
            actions.append(goToArtistAction)
        }
		menuBuilder.with(options: actions)
    }

    
    //MARK: - Search Bar Delegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		guard !searchText.isEmpty else { return }
		
		let normalizedSearchText = searchText.normalizedString
		guard (self.searchText ?? "") != normalizedSearchText else {
			return
		}
		
		self.searchText = normalizedSearchText
		let searchStringComponents = normalizedSearchText.components(separatedBy: " ")
		
		for searchExecutor in searchExecutionControllers {
			searchExecutor.executeSearchForStringComponents(normalizedSearchText, stringComponents: searchStringComponents)
		}
    }
    
    
    //MARK: - SearchExecutionController Delegate
    func searchResultsDidGetUpdated(_ searchExecutionController:SearchExecutionController) {
        if tableView.isEditing {
            toggleSelectMode()
        }
        reloadTableViewData()
    }
    
    func searchDidComplete(_ searchExecutionController:SearchExecutionController) {
        if !searchExecutionControllers.contains(where: { $0.searchInProgress }){
            reloadTableViewData()
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
            , rowLimitedDSD.sections.count > 1 && willSelectAll {
            
            let strokeAnimation = CABasicAnimation(keyPath: "strokeColor")
            strokeAnimation.duration = 0.2
            strokeAnimation.toValue = UIColor.white.cgColor

            
            let widthAnimation = CABasicAnimation(keyPath: "lineWidth")
            widthAnimation.duration = 0.2
            widthAnimation.toValue = 1.5
            
            let animationGroup = CAAnimationGroup()
            animationGroup.animations = [strokeAnimation, widthAnimation]
            animationGroup.repeatCount = 1
            animationGroup.autoreverses = true
            
            (0..<tableView.numberOfSections).forEach { section in
                (tableView.headerView(forSection: section) as? KyoozSectionHeaderView)?
                    .strokeLayer
                    .add(animationGroup, forKey: nil)
            }
            
        } else {
            super.selectOrDeselectAll()
        }
    }
    
}
