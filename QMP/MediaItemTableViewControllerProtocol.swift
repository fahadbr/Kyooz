//
//  QueableMediaItemTableViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/9/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

protocol MediaItemTableViewControllerProtocol {
    
    var tableView:UITableView { get }
    
    func getMediaItemsForIndexPath(indexPath:NSIndexPath) -> [AudioTrack]
    
}
