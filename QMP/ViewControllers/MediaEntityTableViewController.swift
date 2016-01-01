//
//  MediaCollectionTableViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 10/4/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class MediaEntityTableViewController: AbstractMediaEntityTableViewController {

    private var sections:[MPMediaQuerySection]?
    private var entities:[MPMediaEntity]!
    
    var subGroups:[LibraryGrouping] = LibraryGrouping.values {
        didSet {
            isBaseLevel = false
        }
    }
    
    private (set) var isBaseLevel:Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerClass(MediaCollectionTableViewCell.self, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
        tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
    }
    
    
    override func getViewForHeader() -> UIView? {
        if subGroups.isEmpty {
            return nil
        }
        
        guard let view = NSBundle.mainBundle().loadNibNamed("LibraryGroupingHeaderView", owner: self, options: nil)?.first as? MediaEntityHeaderView else {
            return nil
        }
        
        
        view.menuButtonBlock = {
            self.toggleSelectMode()
        }
        
        
        let control = UISegmentedControl(items: subGroups.map({ $0.name }))
        control.tintColor = ThemeHelper.defaultTintColor
        
        control.apportionsSegmentWidthsByContent = true
        control.addTarget(self, action: "groupingTypeDidChange:", forControlEvents: UIControlEvents.ValueChanged)
        control.selectedSegmentIndex = 0
        if control.frame.size.width < tableView.frame.width {
            view.mainView.addSubview(control)
            control.translatesAutoresizingMaskIntoConstraints = false
            control.centerXAnchor.constraintEqualToAnchor(view.mainView.centerXAnchor).active = true
            control.centerYAnchor.constraintEqualToAnchor(view.mainView.centerYAnchor).active = true
            return view
        }
        
        let scrollView = UIScrollView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: tableView.frame.width, height: 40)))
        scrollView.contentSize = control.frame.size

        scrollView.addSubview(control)
        scrollView.scrollsToTop = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        view.mainView.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.centerYAnchor.constraintEqualToAnchor(view.mainView.centerYAnchor).active = true
        scrollView.leftAnchor.constraintEqualToAnchor(view.mainView.leftAnchor).active = true
        scrollView.rightAnchor.constraintEqualToAnchor(view.mainView.rightAnchor).active = true
        scrollView.heightAnchor.constraintEqualToAnchor(control.heightAnchor, constant:10).active = true

        return view
    }
    
    private var collectionVC:LibraryGroupCollectionViewController!
    
    private func addCollectionViewControl() {
        collectionVC = LibraryGroupCollectionViewController(items: subGroups)
        collectionVC.view.frame = view.bounds
        collectionVC.view.frame.size.height = collectionVC.estimatedHeight + 60

        tableView.tableHeaderView = collectionVC.view
        addChildViewController(collectionVC)
        collectionVC.didMoveToParentViewController(self)
        collectionVC.collectionView?.scrollsToTop = false
    }
    
    
    func groupingTypeDidChange(sender:UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        let selectedGroup = subGroups[index]
        libraryGroupingType = selectedGroup
        
        if isBaseLevel {
            filterQuery = libraryGroupingType.baseQuery
        } else {
            filterQuery.groupingType = selectedGroup.groupingType
        }
        
        reloadAllData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Table view data source and delegate methods
    //MARK: header configuration
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let view = NSBundle.mainBundle().loadNibNamed("SearchResultsHeaderView", owner: self, options: nil)?.first as? SearchResultsHeaderView else {
            return nil
        }
        guard let sections = self.sections else {
            return nil
        }
        view.headerTitleLabel.text = sections[section].title
        view.disclosureContainerView.hidden = true
        return view
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sections != nil ?  40.0 : 0.0
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        guard let sections = self.sections else {
            return 1
        }
        
        return sections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = self.sections else {
            return entities!.count
        }
        return sections[section].range.length
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        guard let sections = self.sections else {
            return nil
        }
        var titles = [String]()
        for section in sections {
            titles.append(section.title)
        }
        return titles
    }
    
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        //this synchronizes the parent scroll view with the table view after a section index has been selected
        //doing this asynchronously because the tableView's contentOffset is not updated until after this method is called
        KyoozUtils.doInMainQueueAsync() { [weak self] in self?.parentMediaEntityController?.synchronizeOffsetWithScrollview(tableView) }
        return index
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let reuseIdentifier = libraryGroupingType === LibraryGrouping.Albums ? ImageTableViewCell.reuseIdentifier : MediaCollectionTableViewCell.reuseIdentifier

        guard let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) else {
            return UITableViewCell()
        }
        
        let entity = entities[getAbsoluteIndex(indexPath: indexPath)]
        
        
        if var audioCell = cell as? ConfigurableAudioTableCell {
            audioCell.configureCellForItems(entity, mediaGroupingType: libraryGroupingType.groupingType)
            audioCell.isNowPlayingItem = false
            let persistentIdPropertyName = MPMediaItem.persistentIDPropertyForGroupingType(libraryGroupingType.groupingType)
            if let nowPlayingItem = audioQueuePlayer.nowPlayingItem as? MPMediaItem,
                let persistentIdForGroupingType = nowPlayingItem.valueForProperty(persistentIdPropertyName) as? NSNumber {
                
                if persistentIdForGroupingType.unsignedLongLongValue == entity.persistentID {
                    audioCell.isNowPlayingItem = true
                }
            }
        } else {
            cell.textLabel?.text = title
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing {
            super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
            return
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let entity = entities[getAbsoluteIndex(indexPath: indexPath)]
        
        if libraryGroupingType === LibraryGrouping.Songs {
            startPlayingWithItemAtIndex(indexPath)
            return
        }
        
        //go to specific album track view controller if we are selecting an album collection
        
        ContainerViewController.instance.pushNewMediaEntityControllerWithProperties(basePredicates:filterQuery.filterPredicates, parentGroup: libraryGroupingType, entity: entity)
    }
    
    
    //MARK: - Private functions
    
    private func startPlayingWithItemAtIndex(indexPath:NSIndexPath) {
        //note the different behaviours.  if the current entities representation is a mpmediaItem then we play with the entire collection in the view
        //otherwise we play the selected entity only, assuming it is a media item collecion
        if let mediaItems = entities as? [MPMediaItem] {
            audioQueuePlayer.playNow(withTracks: mediaItems, startingAtIndex: getAbsoluteIndex(indexPath: indexPath))
        } else if let collections = entities as? [MPMediaItemCollection] {
            let collection = collections[getAbsoluteIndex(indexPath: indexPath)]
            if collection.count > 0 {
                audioQueuePlayer.playNow(withTracks: collection.items, startingAtIndex: 0)
            }
        }
    }
    
    override func reloadSourceData() {
        entities = nil
        sections = nil
        if libraryGroupingType === LibraryGrouping.Songs {
            guard let items = filterQuery.items else {
                Logger.debug("No items found for query \(filterQuery)")
                return
            }
            entities = items
        } else {
            guard let collections = filterQuery.collections else {
                Logger.debug("No collections found for query \(filterQuery)")
                return
            }
            entities = collections
        }
        
        if entities.count >= 15 {
            guard let sections = libraryGroupingType === LibraryGrouping.Songs ? filterQuery.itemSections : filterQuery.collectionSections else {
                Logger.debug("No sections found for query \(filterQuery)")
                return
            }
            if sections.count <= 1 {
                return
            }
            self.sections = sections
        }
        tableView.estimatedSectionHeaderHeight = sections != nil ? 40 : 0
    }

    private func getAbsoluteIndex(indexPath indexPath: NSIndexPath) -> Int{
        guard let sections = self.sections else {
            return indexPath.row
        }
        
        let offset =  sections[indexPath.section].range.location
        let index = indexPath.row
        let absoluteIndex = offset + index
        
        return absoluteIndex
    }
    
    
    //MARK: - Overriding MediaItemTableViewController methods
    override func getMediaItemsForIndexPath(indexPath: NSIndexPath) -> [AudioTrack] {
        let absoluteIndex = getAbsoluteIndex(indexPath: indexPath)
        if absoluteIndex < entities!.count {
            let entity = entities![absoluteIndex]
            if let collection = entity as? MPMediaItemCollection {
                return collection.items
            } else if let mediaItem = entity as? MPMediaItem {
                return [mediaItem]
            }
            
        }
        return [AudioTrack]()
    }
    
}
