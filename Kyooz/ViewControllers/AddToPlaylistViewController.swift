//
//  AddToPlaylistViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class AddToPlaylistViewController: UINavigationController {
    
    private let tracksToAdd:[AudioTrack]
    private let vcTitle:String
    let completionAction:(()->())?
    
    init(tracksToAdd:[AudioTrack], title:String?, completionAction:(()->())?) {
        self.tracksToAdd = tracksToAdd
        self.vcTitle = title ?? "ADD TO PLAYLIST"
        self.completionAction = completionAction
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0, alpha: 0.4)
        navigationBar.clearBackgroundImage()
		toolbarHidden = false
		

		
        let vc = AudioEntityPlainHeaderViewController()
        vc.automaticallyAdjustsScrollViewInsets = false
	
        var datasourceDelegates = [AudioEntityDSDProtocol]()
		
		if let mostRecentlyModifiedPlaylist = Playlists.mostRecentlyModifiedPlaylist {
			switch mostRecentlyModifiedPlaylist.type {
			case .kyooz:
				break
			case .iTunes:
				if #available(iOS 9.3, *) {
					
				} else {
					fatalError("itunes playlist modification is not supported prior to iOS 9.3")
				}
			}
		}
		
		
		let kyoozPlaylistDSD = AddToKyoozPlaylistDSD(sourceData: KyoozPlaylistManager.instance,
		                                             reuseIdentifier: ImageTableViewCell.reuseIdentifier,
		                                             tracksToAdd: tracksToAdd,
		                                             completion: dismissAddToPlaylistController)
		datasourceDelegates.append(kyoozPlaylistDSD)
		
        let cancelButton = UIBarButtonItem(title:"CANCEL",
                                           style: .Plain,
                                           target: self,
                                           action: #selector(self.dismissOnly))
		
        cancelButton.tintColor = ThemeHelper.defaultTintColor
		
        
        if #available(iOS 9.3, *) {
			func dsdForForPlaylistAttribute(attribute:MPMediaPlaylistAttribute) -> MPMediaQuery {
				let playlistQuery = MPMediaQuery.playlistsQuery()
				playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(
					value: NSNumber(unsignedInteger: attribute.rawValue),
					forProperty: MPMediaPlaylistPropertyPlaylistAttributes,
					comparisonType: .EqualTo))
				
				return playlistQuery
			}
			
            let standardPlaylistsQuery = dsdForForPlaylistAttribute(.None)
            let otgPlaylistsQuery = dsdForForPlaylistAttribute(.OnTheGo)
            let jointQuery = JointMediaQuery(query1: standardPlaylistsQuery, query2: otgPlaylistsQuery)
			
			let queryDatasource = MediaQuerySourceData(filterQuery: jointQuery,
                                                       libraryGrouping: LibraryGrouping.Playlists,
                                                       singleSectionName: "ITUNES PLAYLISTS")
			
			datasourceDelegates.append(AddToAppleMusicPlaylistDSD(sourceData: queryDatasource,
				reuseIdentifier: ImageTableViewCell.reuseIdentifier,
				tracksToAdd: tracksToAdd,
				completion: dismissAddToPlaylistController))
			
            let infoButton = UIBarButtonItem(title: "??", style: .Plain, target: self, action: #selector(self.showInfo))
            infoButton.tintColor = ThemeHelper.defaultTintColor
            vc.toolbarItems = [UIBarButtonItem.flexibleSpace(), cancelButton, UIBarButtonItem.flexibleSpace(), infoButton]
            
        } else {
            vc.toolbarItems = [UIBarButtonItem.flexibleSpace(), cancelButton, UIBarButtonItem.flexibleSpace()]
        }
        
        let sectionDelegator = AudioEntityDSDSectionDelegator(datasources: datasourceDelegates)
        
        vc.title = vcTitle
        vc.sourceData = sectionDelegator
        vc.datasourceDelegate = sectionDelegator
		vc.navigationItem.rightBarButtonItem =  UIBarButtonItem(barButtonSystemItem: .Add,
		                                                        target: self,
		                                                        action: #selector(self.showNewPlaylistMenu))
		
        setViewControllers([vc], animated: false)
		
    }
    
    @available(iOS 9.3, *)
    func showInfo() {
        Playlists.showPlaylistTypeInfoView(self)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
	
	func showNewPlaylistMenu() {
		dismissViewControllerAnimated(true) { [tracksToAdd = self.tracksToAdd] in
			Playlists.showPlaylistCreationControllerForTracks(tracksToAdd)
		}
		completionAction?()
	}
    
    func dismissAddToPlaylistController() {
        dismissViewControllerAnimated(true, completion: nil)
        completionAction?()
    }
    
    func dismissOnly() {
        dismissViewControllerAnimated(true, completion: nil)
    }


}
