//
//  AudioEntityViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/3/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit



final class AudioEntityHeaderViewController : AudioEntityViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
	
    private static let searchButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: RootViewController.instance, action: "activateSearch")
	
	var headerHeightConstraint: NSLayoutConstraint!
	var maxHeight:CGFloat!
	var minHeight:CGFloat!
	var collapsedTargetOffset:CGFloat!
	
	var reuseIdentifier:String {
		if useCollapsableHeader {
			return AlbumTrackTableViewCell.reuseIdentifier
		}
		
		if sourceData.libraryGrouping == LibraryGrouping.Albums {
			return ImageTableViewCell.reuseIdentifier
		}
		return MediaCollectionTableViewCell.reuseIdentifier
	}
	
	var useCollapsableHeader:Bool = false
	private var headerCollapsed:Bool = false
	
	var testMode = false
	var testDelegate:TestTableViewDataSourceDelegate!
    
    
    var subGroups:[LibraryGrouping] = LibraryGrouping.values {
        didSet {
            isBaseLevel = false
        }
    }
    
    private var isBaseLevel:Bool = true
    private var headerVC:HeaderViewController!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.rightBarButtonItem = AudioEntityHeaderViewController.searchButton
		view.backgroundColor = ThemeHelper.darkAccentColor
		popGestureRecognizer.enabled = !isBaseLevel
		popGestureRecognizer.delegate = self
		
        tableView.registerNib(NibContainer.mediaCollectionTableViewCellNib, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
        tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
		tableView.registerNib(NibContainer.albumTrackTableViewCellNib, forCellReuseIdentifier: AlbumTrackTableViewCell.reuseIdentifier)
        tableView.registerClass(SearchHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SearchResultsHeaderView.reuseIdentifier)
        
		headerVC = useCollapsableHeader ? UIStoryboard.artworkHeaderViewController() : UIStoryboard.utilHeaderViewController()
        view.addSubview(headerVC.view)
        headerVC.view.translatesAutoresizingMaskIntoConstraints = false
        headerVC.view.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        headerVC.view.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        headerVC.view.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
		headerHeightConstraint = headerVC.view.heightAnchor.constraintEqualToConstant(headerVC.defaultHeight)
		headerHeightConstraint.active = true
        addChildViewController(headerVC)
        headerVC.didMoveToParentViewController(self)
		
		minHeight = headerVC.minimumHeight
		maxHeight = headerVC.defaultHeight
		collapsedTargetOffset = maxHeight - minHeight
		tableView.contentInset.top = minHeight
		
		if useCollapsableHeader {
			tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: collapsedTargetOffset))
			tableView.scrollIndicatorInsets.top = collapsedTargetOffset
			view.addGestureRecognizer(tableView.panGestureRecognizer)
		}

		if testMode {
			configureTestDelegates()
		} else {
			applyDataSourceAndDelegate()
		}

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
		if !useCollapsableHeader { return }
		let currentOffset = scrollView.contentOffset.y + scrollView.contentInset.top
		
		if  currentOffset < collapsedTargetOffset {
			headerHeightConstraint.constant = (maxHeight - currentOffset)
			scrollView.scrollIndicatorInsets.top = collapsedTargetOffset - scrollView.contentOffset.y
			headerCollapsed = false
		} else if !headerCollapsed {
			headerHeightConstraint.constant = minHeight
//			scrollView.scrollIndicatorInsets.top = 
			headerCollapsed = true
		}
		

	}
    
    //MARK: - Class functions

    func groupingTypeDidChange(selectedGroup:LibraryGrouping) {
        if isBaseLevel {
            sourceData = MediaQuerySourceData(filterQuery: selectedGroup.baseQuery, libraryGrouping: selectedGroup)
        } else {
            if let groupMutableSourceData = sourceData as? GroupMutableAudioEntitySourceData {
                groupMutableSourceData.libraryGrouping = selectedGroup
            }
        }
        tableView.contentOffset = CGPoint.zero
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
