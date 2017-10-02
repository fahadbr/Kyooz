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
		isToolbarHidden = false
		

		
        let vc = AudioEntityPlainHeaderViewController()
        vc.automaticallyAdjustsScrollViewInsets = false
	
        var datasourceDelegates = [AudioEntityDSDProtocol]()
		
		if let recentPlaylist = Playlists.mostRecentlyModifiedPlaylist {
            let recentSourceData = BasicAudioEntitySourceData(collection: recentPlaylist.playlist,
                                                        grouping: LibraryGrouping.Playlists,
                                                        sourceDataName: "RECENT - \(recentPlaylist.type.description)")
            
            
            let recentDSD:AudioEntityDSDProtocol?
			switch recentPlaylist.type {
			case .kyooz:
                guard KyoozPlaylistManager.instance.playlists.contains(recentPlaylist.playlist) else {
                    recentDSD = nil
                    Playlists.setMostRecentlyModified(playlist: nil)
                    break
                }
				recentDSD = AddToKyoozPlaylistDSD(sourceData: recentSourceData,
				                                  reuseIdentifier: ImageTableViewCell.reuseIdentifier,
				                                  tracksToAdd: tracksToAdd,
				                                  completion: dismissAddToPlaylistController)
                
			case .iTunes:
				if #available(iOS 9.3, *) {
                    let query = MPMediaQuery.playlists()
                    query.addFilterPredicate(MPMediaPropertyPredicate(
                        value: NSNumber(value:recentPlaylist.playlist.persistentIdForGrouping(LibraryGrouping.Playlists)),
                        forProperty: MPMediaPlaylistPropertyPersistentID))
                    guard query.collections?.first != nil else {
                        recentDSD = nil
                        Playlists.setMostRecentlyModified(playlist: nil)
                        break
                    }
                    
                    recentDSD = AddToAppleMusicPlaylistDSD(sourceData: recentSourceData,
                                                           reuseIdentifier: ImageTableViewCell.reuseIdentifier,
                                                           tracksToAdd: tracksToAdd,
                                                           completion: dismissAddToPlaylistController)
					
				} else {
					fatalError("itunes playlist modification is not supported prior to iOS 9.3")
				}
			}
            
            if recentDSD != nil {
                datasourceDelegates.append(recentDSD!)
            }
		}
		
		
		let kyoozPlaylistDSD = AddToKyoozPlaylistDSD(sourceData: KyoozPlaylistManager.instance,
		                                             reuseIdentifier: ImageTableViewCell.reuseIdentifier,
		                                             tracksToAdd: tracksToAdd,
		                                             completion: dismissAddToPlaylistController)
		datasourceDelegates.append(kyoozPlaylistDSD)
		
        let cancelButton = UIBarButtonItem(title:"CANCEL",
                                           style: .plain,
                                           target: self,
                                           action: #selector(self.dismissOnly))
		
        cancelButton.tintColor = ThemeHelper.defaultTintColor
		
        
        if #available(iOS 9.3, *) {
			func dsdForForPlaylistAttribute(_ attribute:MPMediaPlaylistAttribute) -> MPMediaQuery {
				let playlistQuery = MPMediaQuery.playlists()
				playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(
					value: NSNumber(value: attribute.rawValue),
					forProperty: MPMediaPlaylistPropertyPlaylistAttributes,
					comparisonType: .equalTo))
				
				return playlistQuery
			}
			
            let standardPlaylistsQuery = dsdForForPlaylistAttribute(MPMediaPlaylistAttribute())
            let otgPlaylistsQuery = dsdForForPlaylistAttribute(.onTheGo)
            let jointQuery = JointMediaQuery(query1: standardPlaylistsQuery, query2: otgPlaylistsQuery)
			
			let queryDatasource = MediaQuerySourceData(filterQuery: jointQuery,
                                                       libraryGrouping: LibraryGrouping.Playlists,
                                                       singleSectionName: "ITUNES PLAYLISTS")
			
			datasourceDelegates.append(AddToAppleMusicPlaylistDSD(sourceData: queryDatasource,
				reuseIdentifier: ImageTableViewCell.reuseIdentifier,
				tracksToAdd: tracksToAdd,
				completion: dismissAddToPlaylistController))
			
            vc.toolbarItems = [UIBarButtonItem.flexibleSpace(), cancelButton, UIBarButtonItem.flexibleSpace()]
            
        } else {
            vc.toolbarItems = [UIBarButtonItem.flexibleSpace(), cancelButton, UIBarButtonItem.flexibleSpace()]
        }
        
        let sectionDelegator = AudioEntityDSDSectionDelegator(datasources: datasourceDelegates)
        
        vc.title = vcTitle
        vc.sourceData = sectionDelegator
        vc.datasourceDelegate = sectionDelegator
		vc.navigationItem.rightBarButtonItem =  UIBarButtonItem(barButtonSystemItem: .add,
		                                                        target: self,
		                                                        action: #selector(self.showNewPlaylistMenu))
		
        setViewControllers([vc], animated: false)
		
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
	
    @objc func showNewPlaylistMenu() {
        Playlists.showPlaylistCreationController(for: tracksToAdd,
                                                 presentationController: self,
                                                 completionAction: dismissAddToPlaylistController)
	}
    
    func dismissAddToPlaylistController() {
        dismiss(animated: true, completion: nil)
        completionAction?()
    }
    
    @objc func dismissOnly() {
        dismiss(animated: true, completion: nil)
    }


}
