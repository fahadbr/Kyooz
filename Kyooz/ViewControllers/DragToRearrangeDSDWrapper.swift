//
//  DragToRearrangeDSDWrapper.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/19/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class DragToRearrangeDSDWrapper : AudioEntityDSDWrapper {

    let originalIndexPath:NSIndexPath
    let tableView:UITableView
    var indexPathOfMovingItem:NSIndexPath
    
    init(tableView:UITableView, datasourceDelegate:AudioEntityDSDProtocol, originalIndexPath:NSIndexPath) {
        self.tableView = tableView
        self.originalIndexPath = originalIndexPath
        self.indexPathOfMovingItem = originalIndexPath
        super.init(sourceDSD: datasourceDelegate)
    }
    
    //MARK: - table view datasource methods
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //since the datasource is not updated while we're rearranging, we need to remap the index path of items moved in the
        //tableView itself to the original source data that is containded within the dataSource
        
        let moddedIndexPath:NSIndexPath
        if indexPath.row > indexPathOfMovingItem.row && indexPath.row <= originalIndexPath.row {
            moddedIndexPath = NSIndexPath(forRow: indexPath.row - 1, inSection: indexPath.section)
        } else if indexPath.row < indexPathOfMovingItem.row && indexPath.row >= originalIndexPath.row {
            moddedIndexPath = NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section)
        } else {
            moddedIndexPath = indexPath
        }
        
        let cell = datasourceDelegate.tableView(tableView, cellForRowAtIndexPath: moddedIndexPath)
        if indexPath == indexPathOfMovingItem {
            cell.hidden = true
        }
        return cell
    }
    
    
    func persistChanges() throws {        
        if originalIndexPath != indexPathOfMovingItem {
            datasourceDelegate.tableView?(tableView, moveRowAtIndexPath: originalIndexPath, toIndexPath: indexPathOfMovingItem)
        }
    }
    
    
}