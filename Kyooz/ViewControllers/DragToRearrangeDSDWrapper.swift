//
//  DragToRearrangeDSDWrapper.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/19/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class DragToRearrangeDSDWrapper : AudioEntityDSDWrapper {

    let originalIndexPath:IndexPath
    let tableView:UITableView
    var indexPathOfMovingItem:IndexPath
    
    init(tableView:UITableView, datasourceDelegate:AudioEntityDSDProtocol, originalIndexPath:IndexPath) {
        self.tableView = tableView
        self.originalIndexPath = originalIndexPath
        self.indexPathOfMovingItem = originalIndexPath
        super.init(sourceDSD: datasourceDelegate)
    }
    
    //MARK: - table view datasource methods
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //since the datasource is not updated while we're rearranging, we need to remap the index path of items moved in the
        //tableView itself to the original source data that is containded within the dataSource
        
        let moddedIndexPath:IndexPath
        if (indexPath as NSIndexPath).row > indexPathOfMovingItem.row && (indexPath as NSIndexPath).row <= (originalIndexPath as NSIndexPath).row {
            moddedIndexPath = IndexPath(row: (indexPath as NSIndexPath).row - 1, section: (indexPath as NSIndexPath).section)
        } else if (indexPath as NSIndexPath).row < indexPathOfMovingItem.row && (indexPath as NSIndexPath).row >= (originalIndexPath as NSIndexPath).row {
            moddedIndexPath = IndexPath(row: (indexPath as NSIndexPath).row + 1, section: (indexPath as NSIndexPath).section)
        } else {
            moddedIndexPath = indexPath
        }
        
        let cell = datasourceDelegate.tableView(tableView, cellForRowAt: moddedIndexPath)
        if indexPath == indexPathOfMovingItem {
            cell.isHidden = true
        }
        return cell
    }
    
    
    func persistChanges() throws {        
        if originalIndexPath != indexPathOfMovingItem {
            datasourceDelegate.tableView?(tableView, moveRowAt: originalIndexPath, to: indexPathOfMovingItem)
        }
    }
    
    
}
