//
//  DragToInsertDSDWrapper.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/15/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

//this class cannot be used with multisection datasources
final class DragToInsertDSDWrapper: DragToRearrangeDSDWrapper {

    var locationInDestinationTableView:Bool = true
    
    override var indexPathOfMovingItem:NSIndexPath {
        didSet {
            if indexPathOfMovingItem.row == sourceData.entities.count || indexPathOfMovingItem.row == 0 {
                placeholderCell?.hidden = false
            } else {
                placeholderCell?.hidden = true
            }
        }
    }
    
    var placeholderCell:UITableViewCell? = {
        let cell = UITableViewCell()
        cell.backgroundColor = ThemeHelper.defaultTableCellColor
        cell.textLabel?.text = "Insert Here"
        cell.textLabel?.textAlignment = NSTextAlignment.Center
        cell.textLabel?.font = ThemeHelper.defaultFont
        cell.textLabel?.textColor = UIColor.grayColor()
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        cell.layer.shouldRasterize = true
        cell.hidden = true
        return cell
    }()
    
    private let entitiesToInsert:[AudioEntity]
    
    init(tableView: UITableView, datasourceDelegate: AudioEntityDSDProtocol, originalIndexPath: NSIndexPath, entitiesToInsert:[AudioEntity]) {
        self.entitiesToInsert = entitiesToInsert
        super.init(tableView: tableView, datasourceDelegate: datasourceDelegate, originalIndexPath: originalIndexPath)
    }
    
    //MARK: - table view datasource methods
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = datasourceDelegate.tableView(tableView, numberOfRowsInSection: section)
        return placeholderCell == nil ? count : count + 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var indexPathToUse = indexPath
        if let placeholderCell = self.placeholderCell {
            if indexPath == indexPathOfMovingItem {
                return placeholderCell
            }
            
            if indexPathOfMovingItem.row < indexPath.row {
                indexPathToUse = NSIndexPath(forRow: indexPath.row - 1, inSection: indexPath.section)
            }
        }
        return datasourceDelegate.tableView(tableView, cellForRowAtIndexPath: indexPathToUse)
    }
    
    override func persistChanges() throws {
        placeholderCell = nil
        
        tableView.deleteRowsAtIndexPaths([indexPathOfMovingItem], withRowAnimation: .None)
        
        guard let destinationSourceData = self.sourceData as? MutableAudioEntitySourceData where locationInDestinationTableView else {
            return
        }
        
        let noOfItemsToInsert = try destinationSourceData.insertEntities(entitiesToInsert, atIndexPath: indexPathOfMovingItem)
        let startingIndex = indexPathOfMovingItem.row
        
        var indexPaths = [NSIndexPath]()
        indexPaths.reserveCapacity(noOfItemsToInsert)
        for index in startingIndex ..< (startingIndex + noOfItemsToInsert)  {
            indexPaths.append(NSIndexPath(forRow: index, inSection: 0))
        }
        
        tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: noOfItemsToInsert == 1 ? .Fade : .Automatic)

    }

}
