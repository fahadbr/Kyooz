//
//  ParentMediaEntityViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/3/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class AudioEntityViewController: CustomPopableViewController, AudioEntityViewControllerProtocol, AudioTableCellDelegate {
    
    class var shouldAnimateInArtworkDefault: Bool {
        return true
    }
    
    lazy var audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    let tableView:UITableView = UITableView()
	
	var sourceData:AudioEntitySourceData = MediaQuerySourceData(filterQuery: LibraryGrouping.Artists.baseQuery, libraryGrouping: LibraryGrouping.Artists)
	
	var datasourceDelegate:AudioEntityDSDProtocol! {
		didSet {
			tableView.dataSource = datasourceDelegate
			tableView.delegate = datasourceDelegate
		}
	}
	
	lazy var shouldAnimateInArtwork:Bool = self.dynamicType.shouldAnimateInArtworkDefault
    
	
	//MARK: - View Lifecycle functions
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(NibContainer.mediaCollectionTableViewCellNib, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
        tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
        tableView.registerClass(KyoozSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: KyoozSectionHeaderView.reuseIdentifier)
		
		view.add(subView: tableView, with: .Top, .Left, .Right)
		tableView.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.topAnchor).active = true
		
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        tableView.rowHeight = ThemeHelper.tableViewRowHeight
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.showsVerticalScrollIndicator = true
        tableView.indicatorStyle = .White
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadTableViewData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        registerForNotifications()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        unregisterForNotifications()
    }
    
    deinit {
        unregisterForNotifications()
    }
    
    //MARK: - Class functions
    func reloadAllData() {
        reloadSourceData()
        reloadTableViewData()
    }
    
    func reloadTableViewData() {
        tableView.reloadData()
    }
    
    func reloadTableViewUnanimated() {
        shouldAnimateInArtwork = false
        reloadTableViewData()
        KyoozUtils.doInMainQueueAsync {
            self.shouldAnimateInArtwork = self.dynamicType.shouldAnimateInArtworkDefault
        }
    }
    
    func reloadSourceData() {
        sourceData.reloadSourceData()
    }
    

    //MARK: - AudioCellDelegate
    
    func presentActionsForCell(cell:UITableViewCell, title:String?, details:String?, originatingCenter:CGPoint) {
        guard !tableView.editing  else { return }
        guard let indexPath = tableView.indexPathForCell(cell) else {
            Logger.error("no index path found for cell with tile \(title)")
            return
        }
        
        let tracks = sourceData.getTracksAtIndex(indexPath)
		let b = MenuBuilder().with(title: title)
			.with(details: details)
			.with(originatingCenter: originatingCenter)
		
        if tracks.count == 1 {
			b.with(options:KyoozMenuAction(title: "PLAY ONLY THIS") {
                self.audioQueuePlayer.playNow(withTracks: tracks, startingAtIndex: 0, shouldShuffleIfOff: false)
            })
        }
        KyoozUtils.addDefaultQueueingActions(tracks, menuBuilder: b)
        
        
        addCustomMenuActions(indexPath, tracks: tracks, menuBuilder: b)
        
        KyoozUtils.showMenuViewController(b.viewController)

    }

    
	func addCustomMenuActions(indexPath:NSIndexPath, tracks:[AudioTrack], menuBuilder: MenuBuilder) {
        //empty implementation
    }
    
    
    func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self,
                                       selector: #selector(self.reloadTableViewUnanimated),
                                       name: AudioQueuePlayerUpdate.nowPlayingItemChanged.rawValue,
                                       object: audioQueuePlayer)
        //TODO: Why does this class need to know about playback state updates?
        notificationCenter.addObserver(self,
                                       selector: #selector(self.reloadTableViewUnanimated),
                                       name: AudioQueuePlayerUpdate.playbackStateUpdate.rawValue,
                                       object: audioQueuePlayer)
        
        notificationCenter.addObserver(self,
                                       selector: #selector(self.reloadAllData),
                                       name: MPMediaLibraryDidChangeNotification,
                                       object: MPMediaLibrary.defaultMediaLibrary())
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}