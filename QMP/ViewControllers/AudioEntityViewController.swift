//
//  ParentMediaEntityViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/3/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class AudioEntityViewController : CustomPopableViewController, MediaItemTableViewControllerProtocol, ConfigurableAudioTableCellDelegate {
    
    let fatalErrorMessage = "Unsupported operation. this is an abstract class"
    let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    @IBOutlet var tableView:UITableView!
	
	var sourceData:AudioEntitySourceData = MediaQuerySourceData(filterQuery: LibraryGrouping.Artists.baseQuery, libraryGrouping: LibraryGrouping.Artists)
	
	var datasourceDelegate:AudioEntityDSDProtocol! {
		didSet {
			tableView.dataSource = datasourceDelegate
			tableView.delegate = datasourceDelegate
		}
	}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        tableView.rowHeight = 60
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.showsVerticalScrollIndicator = true
        tableView.indicatorStyle = .White
        
        reloadSourceData()
        registerForNotifications()
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
    
    func reloadSourceData() {
        sourceData.reloadSourceData()
    }
    
    //MARK: - Overriding MediaItemTableViewController methods
    func getMediaItemsForIndexPath(indexPath: NSIndexPath) -> [AudioTrack] {
        return sourceData.getTracksAtIndex(indexPath)
    }
    
    //MARK: - MediaLibraryTableViewCellDelegate
    
	func presentActionsForIndexPath(indexPath:NSIndexPath, title:String?, details:String?, originatingCenter:CGPoint) {
        let tracks = getMediaItemsForIndexPath(indexPath)
        let kmvc = KyoozMenuViewController()
        kmvc.menuTitle = title
		kmvc.menuDetails = details
		kmvc.originatingCenter = originatingCenter
        
        if tracks.count == 1 {
            kmvc.addAction(KyoozMenuAction(title: "Play Only This", image: nil) {
                self.audioQueuePlayer.playNow(withTracks: tracks, startingAtIndex: 0, shouldShuffleIfOff: false)
            })
        }
        KyoozUtils.addDefaultQueueingActions(tracks, menuController: kmvc)
        
        
        addCustomMenuActions(indexPath, menuController:kmvc)
        
        kmvc.addAction(KyoozMenuAction(title: "Cancel", image: nil, action: nil))
        KyoozUtils.showMenuViewController(kmvc)

    }

    
    func addCustomMenuActions(indexPath:NSIndexPath, menuController:KyoozMenuViewController) {
        //empty implementation
    }
    
    
    private func registerForNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "reloadTableViewData",
            name: AudioQueuePlayerUpdate.NowPlayingItemChanged.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadTableViewData",
            name: AudioQueuePlayerUpdate.PlaybackStateUpdate.rawValue, object: audioQueuePlayer)
        notificationCenter.addObserver(self, selector: "reloadAllData",
            name: MPMediaLibraryDidChangeNotification, object: MPMediaLibrary.defaultMediaLibrary())
    }
    
    private func unregisterForNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}
