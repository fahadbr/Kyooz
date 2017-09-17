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
	
	lazy var shouldAnimateInArtwork:Bool = type(of: self).shouldAnimateInArtworkDefault
    
	
	//MARK: - View Lifecycle functions
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(NibContainer.mediaCollectionTableViewCellNib, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
        tableView.register(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
        tableView.register(KyoozSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: KyoozSectionHeaderView.reuseIdentifier)
		
		view.add(subView: tableView, with: .top, .left, .right)
		tableView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
		
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        tableView.rowHeight = ThemeHelper.tableViewRowHeight
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.showsVerticalScrollIndicator = true
        tableView.indicatorStyle = .white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadTableViewUnanimated()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerForNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unregisterForNotifications()
    }
    
    deinit {
        unregisterForNotifications()
    }
    
    //MARK: - Class functions
    func reloadAllData() {
        reloadSourceData()
        reloadTableViewUnanimated()
    }
    
    func reloadTableViewData() {
        tableView.reloadData()
    }
    
    func reloadTableViewUnanimated() {
        shouldAnimateInArtwork = false
        reloadTableViewData()
        KyoozUtils.doInMainQueueAsync {
            self.shouldAnimateInArtwork = type(of: self).shouldAnimateInArtworkDefault
        }
    }
    
    func reloadSourceData() {
        sourceData.reloadSourceData()
    }
    

    //MARK: - AudioCellDelegate
    
    func presentActionsForCell(_ cell:UITableViewCell, title:String?, details:String?, originatingCenter:CGPoint) {
        guard !tableView.isEditing  else { return }
        guard let indexPath = tableView.indexPath(for: cell) else {
            Logger.error("no index path found for cell with tile \(String(describing: title))")
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

    
	func addCustomMenuActions(_ indexPath:IndexPath, tracks:[AudioTrack], menuBuilder: MenuBuilder) {
        //empty implementation
    }
    
    
    func registerForNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            forName: AudioQueuePlayerUpdate.nowPlayingItemChanged.notification,
            object: audioQueuePlayer,
            queue: OperationQueue.main,
            using: { _ in self.reloadTableViewUnanimated() }
        )
        //TODO: Why does this class need to know about playback state updates?
        notificationCenter.addObserver(
            forName: AudioQueuePlayerUpdate.playbackStateUpdate.notification,
            object: audioQueuePlayer,
            queue: OperationQueue.main,
            using: { _ in self.reloadTableViewUnanimated() }
        )
        notificationCenter.addObserver(
            forName: NSNotification.Name.MPMediaLibraryDidChange,
            object: MPMediaLibrary.default(),
            queue: OperationQueue.main,
            using: { _ in self.reloadAllData() }
        )
    }
    
    private func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
}
