//
//  AudioEntityViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/3/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit



final class AudioEntityHeaderViewController : AudioEntityViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
	
    private enum HeaderState : Int {
        case Collapsed, Expanded, Transitioning
    }
    private static let searchButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: RootViewController.instance, action: "activateSearch")
    
	@IBOutlet var headerView:UIView!
	
	@IBOutlet var headerTopAnchorConstraint:NSLayoutConstraint!
	@IBOutlet var headerHeightConstraint: NSLayoutConstraint!
	@IBOutlet var tableViewTopAnchorConstraint: NSLayoutConstraint!
	
	var maxHeight:CGFloat!
	var minHeight:CGFloat!
	var collapsedTargetOffset:CGFloat!
	
	var reuseIdentifier:String {
		if useCollectionDetailsHeader {
			return AlbumTrackTableViewCell.reuseIdentifier
		}
		
		if sourceData.libraryGrouping == LibraryGrouping.Albums {
			return ImageTableViewCell.reuseIdentifier
		}
		return MediaCollectionTableViewCell.reuseIdentifier
	}
	
	var useCollectionDetailsHeader:Bool = false
    private var shouldCollapseHeaderView = true
	private var headerState:HeaderState = .Expanded
	
	var testMode = false
	var testDelegate:TestTableViewDataSourceDelegate!
    
    
    var subGroups:[LibraryGrouping] = LibraryGrouping.values {
        didSet {
            isBaseLevel = false
        }
    }
    
    private (set) var isBaseLevel:Bool = true
    var headerVC:HeaderViewController!
	
	override func viewDidLoad() {
        super.viewDidLoad()
        shouldCollapseHeaderView = useCollectionDetailsHeader
		navigationItem.rightBarButtonItem = AudioEntityHeaderViewController.searchButton
        
        tableView.registerNib(NibContainer.mediaCollectionTableViewCellNib, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
        tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
        tableView.registerClass(SearchHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SearchResultsHeaderView.reuseIdentifier)
        
        headerVC = getHeaderViewController()
        headerView.addSubview(headerVC.view)
        headerVC.view.translatesAutoresizingMaskIntoConstraints = false
        headerVC.view.topAnchor.constraintEqualToAnchor(headerView.topAnchor).active = true
        headerVC.view.bottomAnchor.constraintEqualToAnchor(headerView.bottomAnchor).active = true
        headerVC.view.leftAnchor.constraintEqualToAnchor(headerView.leftAnchor).active = true
        headerVC.view.rightAnchor.constraintEqualToAnchor(headerView.rightAnchor).active = true
        addChildViewController(headerVC)
        headerVC.didMoveToParentViewController(self)
        
        popGestureRecognizer.enabled = !isBaseLevel
        popGestureRecognizer.delegate = self
        
		if testMode {
			configureTestDelegates()
		} else {
			applyDataSourceAndDelegate()
		}
    
		view.backgroundColor = ThemeHelper.darkAccentColor

		NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadAllData",
			name: KyoozPlaylistManager.PlaylistSetUpdate, object: KyoozPlaylistManager.instance)
	}
	
	private func configureTestDelegates() {
		testDelegate = TestTableViewDataSourceDelegate()
		//        testDelegate.mediaEntityTVC = self
		tableView.dataSource = testDelegate
		tableView.delegate = testDelegate
		tableView.sectionHeaderHeight = 40
		tableView.rowHeight = 60
	}
	
	//MARK: - Scroll View Delegate
	
	final func scrollViewDidScroll(scrollView: UIScrollView) {
		if !shouldCollapseHeaderView { return }
		let currentOffset = scrollView.contentOffset.y
		
		if  currentOffset < collapsedTargetOffset {
			applyTransformToHeaderUsingOffset(currentOffset)
			scrollView.scrollIndicatorInsets.top = collapsedTargetOffset - currentOffset
		} else if headerState != .Collapsed {
			applyTransformToHeaderUsingOffset(collapsedTargetOffset)
		}
	}
	
	
	private func applyTransformToHeaderUsingOffset(offset:CGFloat) {
		headerHeightConstraint.constant = (maxHeight - offset)
		let fraction = offset/collapsedTargetOffset
		
		if fraction == 1 {
			headerState = .Collapsed
		} else if fraction == 0 {
			headerState = .Expanded
		} else {
			headerState = .Transitioning
		}
	}
    
    //MARK: - Class functions
    
    func updateConstraints() {
        if headerVC is ArtworkHeaderViewController {
            headerTopAnchorConstraint.active = false
            headerTopAnchorConstraint = headerView.topAnchor.constraintEqualToAnchor(view.topAnchor)
            headerTopAnchorConstraint.active = true
            tableViewTopAnchorConstraint.active = false
            tableViewTopAnchorConstraint = tableView.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: minHeight)
            tableViewTopAnchorConstraint.active = true
            tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: collapsedTargetOffset))
            tableView.scrollIndicatorInsets.top = collapsedTargetOffset
            view.addGestureRecognizer(tableView.panGestureRecognizer)
        }
    }
    
    private func getHeaderViewController() -> HeaderViewController {
        if useCollectionDetailsHeader {
            return UIStoryboard.artworkHeaderViewController()
        }
        return UIStoryboard.utilHeaderViewController()
    }
    
    
    func groupingTypeDidChange(selectedGroup:LibraryGrouping) {
        if isBaseLevel {
            sourceData = MediaQuerySourceData(filterQuery: selectedGroup.baseQuery, libraryGrouping: selectedGroup)
        } else {
            if let groupMutableSourceData = sourceData as? GroupMutableAudioEntitySourceData {
                groupMutableSourceData.libraryGrouping = selectedGroup
            }
        }
        
        applyDataSourceAndDelegate()
        reloadAllData()
    }
    
    
    override func addCustomMenuActions(indexPath: NSIndexPath, alertController: UIAlertController) {
        switch sourceData.libraryGrouping {
        case LibraryGrouping.Playlists:
            guard sourceData[indexPath] is KyoozPlaylist else { return }
            alertController.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: {_ in
                self.datasourceDelegate?.tableView?(self.tableView, commitEditingStyle: .Delete, forRowAtIndexPath: indexPath)
            }))
        default:
            break
        }
    }
    
    
    func applyDataSourceAndDelegate() {
        switch sourceData.libraryGrouping {
        case LibraryGrouping.Songs:
            if sourceData is KyoozPlaylistSourceData {
                datasourceDelegate = EditableAudioTrackDSD(sourceData: sourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: self)
            } else {
                datasourceDelegate = AudioTrackDSD(sourceData: sourceData, reuseIdentifier:  reuseIdentifier, audioCellDelegate: self)
            }
        case LibraryGrouping.Playlists:
            let playlistSourceData = MediaQuerySourceData(filterQuery: LibraryGrouping.Playlists.baseQuery, libraryGrouping: LibraryGrouping.Playlists, singleSectionName: "ITUNES PLAYLISTS")
            let playlistDSD = AudioTrackCollectionDSD(sourceData:playlistSourceData, reuseIdentifier: reuseIdentifier, audioCellDelegate: self)
            let kPlaylistDSD = KyoozPlaylistManagerDSD(sourceData: KyoozPlaylistManager.instance, reuseIdentifier: reuseIdentifier, audioCellDelegate: self)
            let delegator = AudioEntityDSDSectionDelegator(datasources: [kPlaylistDSD, playlistDSD])
            
            sourceData = delegator
            datasourceDelegate = delegator
        default:
            datasourceDelegate = AudioTrackCollectionDSD(sourceData:sourceData, reuseIdentifier:reuseIdentifier, audioCellDelegate:self)
        }
    }
    
	
	
	//MARK: - GESTURE RECOGNIZER DELEGATE
	final func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if otherGestureRecognizer === popGestureRecognizer {
			return gestureRecognizer === tableView.panGestureRecognizer
		}
		return false
	}
	final func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return false
	}
	
	final func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer === popGestureRecognizer {
			return otherGestureRecognizer === tableView.panGestureRecognizer
		}
		return false
	}
	
}
