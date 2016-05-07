//
//  AddToPlaylistViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class AddToPlaylistViewController: UIViewController {
    
    private let tracksToAdd:[AudioTrack]
    let completionAction:(()->())?
    
    init(tracksToAdd:[AudioTrack], completionAction:(()->())?) {
        self.tracksToAdd = tracksToAdd
        self.completionAction = completionAction
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0, alpha: 0.4)
        @available(iOS 9.3, *)
        func dsdForForPlaylistAttribute(attribute:MPMediaPlaylistAttribute) -> MPMediaQuery {
            let playlistQuery = MPMediaQuery.playlistsQuery()
            playlistQuery.addFilterPredicate(MPMediaPropertyPredicate(
                value: NSNumber(unsignedInteger: attribute.rawValue),
                forProperty: MPMediaPlaylistPropertyPlaylistAttributes,
                comparisonType: .EqualTo))
            return playlistQuery
        }
        
        func createFlexibleSpace() -> UIBarButtonItem {
            return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        }

        let vc = AudioEntityPlainHeaderViewController()
        vc.automaticallyAdjustsScrollViewInsets = false
        
        
        let kyoozPlaylistDSD = AddToKyoozPlaylistDSD(sourceData: KyoozPlaylistManager.instance, reuseIdentifier: ImageTableViewCell.reuseIdentifier, tracksToAdd: tracksToAdd, callbackVC: self)
        var datasourceDelegates:[AudioEntityDSDProtocol] = [kyoozPlaylistDSD]
        
        if #available(iOS 9.3, *) {
            let standardPlaylistsQuery = dsdForForPlaylistAttribute(.None)
            let otgPlaylistsQuery = dsdForForPlaylistAttribute(.OnTheGo)
            let jointQuery = JointMediaQuery(query1: standardPlaylistsQuery, query2: otgPlaylistsQuery)
            let queryDatasource = MediaQuerySourceData(filterQuery: jointQuery, libraryGrouping: LibraryGrouping.Playlists, singleSectionName: "ITUNES PLAYLISTS")
            datasourceDelegates.append(AddToAppleMusicPlaylistDSD(sourceData: queryDatasource, reuseIdentifier: ImageTableViewCell.reuseIdentifier, tracksToAdd: tracksToAdd, callbackVC: self))
        }
        
        let sectionDelegator = AudioEntityDSDSectionDelegator(datasources: datasourceDelegates, showEmptySections: true)
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(self.dismissOnly))
        cancelButton.tintColor = ThemeHelper.defaultTintColor
        
        vc.title = "ADD TO PLAYLIST"
        vc.toolbarItems = [createFlexibleSpace(), cancelButton, createFlexibleSpace()]
        vc.sourceData = sectionDelegator
        vc.datasourceDelegate = sectionDelegator
        
        let navController = UINavigationController(rootViewController: vc)
        navController.navigationBar.backgroundColor = UIColor.clearColor()
        navController.navigationBar.setBackgroundImage(UIImage(), forBarPosition: .Any, barMetrics: .Default)
        navController.navigationBar.shadowImage = UIImage()
        
        ConstraintUtils.applyStandardConstraintsToView(subView: navController.view, parentView: view)
        addChildViewController(navController)
        navController.didMoveToParentViewController(self)
        navController.toolbarHidden = false
    }
    
    func dismissAddToPlaylistController() {
        dismissViewControllerAnimated(true, completion: nil)
        completionAction?()
    }
    
    func dismissOnly() {
        dismissViewControllerAnimated(true, completion: nil)
    }


}
