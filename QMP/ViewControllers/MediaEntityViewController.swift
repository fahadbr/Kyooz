//
//  MediaEntityViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/19/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

class MediaEntityViewController: AbstractViewController, MediaItemTableViewControllerProtocol {


    @IBOutlet weak var topView: UIView!
    var mediaEntityTVC:AbstractMediaEntityTableViewController!

    @IBOutlet weak var topViewHeightConstraint: NSLayoutConstraint!
    
    //MARK: - MediaItemTableViewControllerProtocol methods
    var tableView:UITableView! {
        return mediaEntityTVC.tableView
    }
    
    func getMediaItemsForIndexPath(indexPath:NSIndexPath) -> [AudioTrack] {
        return mediaEntityTVC.getMediaItemsForIndexPath(indexPath)
    }
    

    
    //MARK: - View life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        if mediaEntityTVC == nil {
            mediaEntityTVC = MediaEntityTableViewController()
        }
        
        if let headerView = mediaEntityTVC.getViewForHeader() {
            topViewHeightConstraint.constant = mediaEntityTVC.headerHeight
            topView.addSubview(headerView)
            headerView.translatesAutoresizingMaskIntoConstraints = false
            headerView.topAnchor.constraintEqualToAnchor(topView.topAnchor).active = true
            headerView.leftAnchor.constraintEqualToAnchor(topView.leftAnchor).active = true
            headerView.rightAnchor.constraintEqualToAnchor(topView.rightAnchor).active = true
            headerView.bottomAnchor.constraintEqualToAnchor(topView.bottomAnchor).active = true
            
        }
        automaticallyAdjustsScrollViewInsets = false
        let mView = mediaEntityTVC.view
        view.insertSubview(mView, atIndex: 0)
        mediaEntityTVC.automaticallyAdjustsScrollViewInsets = false
        mediaEntityTVC.edgesForExtendedLayout = UIRectEdge.None
        addChildViewController(mediaEntityTVC)
        mediaEntityTVC.didMoveToParentViewController(self)
        
        mView.translatesAutoresizingMaskIntoConstraints = false
        mView.topAnchor.constraintEqualToAnchor(topView.bottomAnchor).active = true
        mView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        mView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        mView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        
        view.backgroundColor = ThemeHelper.defaultTableCellColor
    }

}
