//
//  HeaderViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/2/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

private let selectAllString = "Select All"
private let deselectAllString = "Deselect All"


class HeaderViewController : UIViewController {
	
	private static let fixedHeight:CGFloat = 100
	
    var defaultHeight:CGFloat { return HeaderViewController.fixedHeight }
    var minimumHeight:CGFloat { return HeaderViewController.fixedHeight }
    
    let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    private var tableView:UITableView!
    private var sourceData:AudioEntitySourceData!
    
    @IBOutlet var shuffleButton: ShuffleButtonView!
    @IBOutlet var selectModeButton: MultiSelectButtonView!
    
    
    private lazy var addToButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(HeaderViewController.showAddToOptions(_:)))
    private lazy var selectAllButton:UIBarButtonItem = UIBarButtonItem(title: selectAllString, style: .Plain, target: self, action: #selector(HeaderViewController.selectOrDeselectAll))
    private lazy var deleteButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(HeaderViewController.deleteSelectedItems))
    
    private lazy var playButton:UIBarButtonItem = {
        let playButtonView = PlayPauseButtonView()
        playButtonView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 40, height: 40))
        playButtonView.isPlayButton = true
        playButtonView.hasOuterFrame = false
        playButtonView.color = ThemeHelper.defaultTintColor
        playButtonView.addTarget(self, action: #selector(HeaderViewController.playSelectedTracks(_:)), forControlEvents: .TouchUpInside)
        return UIBarButtonItem(customView: playButtonView)
    }()
    
    private lazy var shuffleToolbarButton:UIBarButtonItem = {
        let shuffleButtonView = ShuffleButtonView()
        shuffleButtonView.color = ThemeHelper.defaultTintColor
        shuffleButtonView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 40, height: 40))
        shuffleButtonView.addTarget(self, action: #selector(HeaderViewController.playSelectedTracks(_:)), forControlEvents: .TouchUpInside)
        return UIBarButtonItem(customView: shuffleButtonView)
    }()
    
    //MARK: - FUNCTIONS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shuffleButton.alpha = ThemeHelper.defaultButtonTextAlpha
        selectModeButton.alpha = ThemeHelper.defaultButtonTextAlpha
        selectModeButton.scale = 0.5
    }
    
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        super.didMoveToParentViewController(parent)
        guard let aehVC = parent as? AudioEntityHeaderViewController else {
            (shuffleButton.superview as? UIStackView)?.hidden = true
			return
		}
        
        tableView = aehVC.tableView
        sourceData = aehVC.sourceData
    }
    
    
    private func createToolbarItems() -> [UIBarButtonItem] {
        func createFlexibleSpace() -> UIBarButtonItem {
            return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        }
        
        var toolbarItems = [playButton, createFlexibleSpace(), shuffleToolbarButton, createFlexibleSpace(), addToButton]
        
        if sourceData is MutableAudioEntitySourceData {
            toolbarItems.append(createFlexibleSpace())
            toolbarItems.append(deleteButton)
        }
        toolbarItems.append(createFlexibleSpace())
        toolbarItems.append(selectAllButton)
        
        let tintColor = ThemeHelper.defaultTintColor
        toolbarItems.forEach() {
            $0.tintColor = tintColor
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HeaderViewController.refreshButtonStates), name: UITableViewSelectionDidChangeNotification, object: tableView)
        return toolbarItems
    }
	
	@IBAction func toggleSelectMode(sender:UIButton?) {
		guard tableView != nil && sourceData != nil else {
			Logger.error("cannot go into select mode with a null tableView or sourceData object")
			return
		}
		
		let willEdit = !tableView.editing
		
		tableView.setEditing(willEdit, animated: true)
		RootViewController.instance.setToolbarHidden(!willEdit)
		
		if willEdit && parentViewController?.toolbarItems == nil {
			parentViewController?.toolbarItems = createToolbarItems()
		}
		
		selectModeButton?.isActive = willEdit
		
		refreshButtonStates()
	}
    
    @IBAction func shuffleAllItems(sender:UIButton?) {
        playAllItems(sender, shouldShuffle: true)
    }
    
    private func playAllItems(sender:UIButton?, shouldShuffle:Bool) {
        KyoozUtils.doInMainQueueAsync() { [sourceData = self.sourceData] in
            if let items = (sourceData as? MediaQuerySourceData)?.filterQuery.items where !items.isEmpty {
                self.playTracks(items, shouldShuffle: shouldShuffle)
            }
        }
    }
    
    private func playTracks(tracks:[AudioTrack], shouldShuffle:Bool) {
        audioQueuePlayer.playNow(withTracks: tracks, startingAtIndex: shouldShuffle ? KyoozUtils.randomNumber(belowValue: tracks.count):0, shouldShuffleIfOff: shouldShuffle)
    }
    
    
    func refreshButtonStates() {
        let isNotEmpty = tableView.indexPathsForSelectedRows != nil
        
        playButton.enabled = isNotEmpty
        deleteButton.enabled = isNotEmpty
        addToButton.enabled = isNotEmpty
        shuffleToolbarButton.enabled = isNotEmpty
        selectAllButton.title = isNotEmpty ? deselectAllString : selectAllString
    }
    
    func selectOrDeselectAll() {
        if let selectedIndicies = tableView.indexPathsForSelectedRows {
            for indexPath in selectedIndicies {
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
            }
        } else {
            for section in 0 ..< tableView.numberOfSections {
                for row in 0 ..< tableView.numberOfRowsInSection(section) {
                    let indexPath = NSIndexPath(forRow: row, inSection: section)
                    tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
                }
            }
        }
        
        refreshButtonStates()
    }
    
    private func getOrderedTracks() -> [AudioTrack]? {
        guard var selectedIndicies = tableView.indexPathsForSelectedRows else { return nil }
        
        selectedIndicies.sortInPlace { (first, second) -> Bool in
            if first.section != second.section {
                return first.section < second.section
            }
            return first.row < second.row
        }
        
        var items = [AudioTrack]()
        for indexPath in selectedIndicies {
            items.appendContentsOf(sourceData.getTracksAtIndex(indexPath))
        }
        return items
    }
    
    func playSelectedTracks(sender:AnyObject!) {
        guard let tracks = getOrderedTracks() else { return }
        
        playTracks(tracks, shouldShuffle: (sender != nil && sender is ShuffleButtonView))
        
        selectOrDeselectAll()
        toggleSelectMode(nil)
    }
    
    func showAddToOptions(sender:UIBarButtonItem!) {
        guard let items = getOrderedTracks() else { return }
        let kmvc = KyoozMenuViewController()
        kmvc.menuTitle = "\(tableView.indexPathsForSelectedRows?.count ?? 0) Selected Items"
        KyoozUtils.addDefaultQueueingActions(items, menuController: kmvc) {
            self.selectOrDeselectAll()
            self.toggleSelectMode(nil)
        }
        
        KyoozUtils.showMenuViewController(kmvc)
    }
    
    
    func deleteSelectedItems() {
        
        let kmvc = KyoozMenuViewController()
        kmvc.menuTitle = "Delete \(tableView.indexPathsForSelectedRows?.count ?? 0) Selected Items?"
        kmvc.addActions([KyoozMenuAction(title:"YES", image: nil) {
            self.deleteInternal()
        }])
        KyoozUtils.showMenuViewController(kmvc)
        
    }
    
    private func deleteInternal() {
        guard let mutableSourceData = self.sourceData as? MutableAudioEntitySourceData, let selectedIndicies = tableView.indexPathsForSelectedRows else {
            return
        }
        do {
            try mutableSourceData.deleteEntitiesAtIndexPaths(selectedIndicies)
            tableView.deleteRowsAtIndexPaths(selectedIndicies, withRowAnimation: .Automatic)
            refreshButtonStates()
        } catch let error {
            KyoozUtils.showPopupError(withTitle: "Error occured while deleting items", withThrownError: error, presentationVC: nil)
        }
        
    }

    
    
}
