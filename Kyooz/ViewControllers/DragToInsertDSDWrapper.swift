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
    
    override var indexPathOfMovingItem:IndexPath {
        didSet {
            if indexPathOfMovingItem.row == sourceData.entities.count || indexPathOfMovingItem.row == 0 {
                placeholderCell?.isHidden = false
            } else {
                placeholderCell?.isHidden = true
            }
        }
    }
    
    var placeholderCell:UITableViewCell? = {
        let cell = UITableViewCell()
        cell.backgroundColor = ThemeHelper.defaultTableCellColor
        cell.textLabel?.text = "Insert Here"
        cell.textLabel?.textAlignment = NSTextAlignment.center
        cell.textLabel?.font = ThemeHelper.defaultFont
        cell.textLabel?.textColor = UIColor.gray
        cell.layer.rasterizationScale = UIScreen.main.scale
        cell.layer.shouldRasterize = true
        cell.isHidden = true
        return cell
    }()
    
    private let entitiesToInsert:[AudioEntity]
    
    init(tableView: UITableView, datasourceDelegate: AudioEntityDSDProtocol, originalIndexPath: IndexPath, entitiesToInsert:[AudioEntity]) {
        self.entitiesToInsert = entitiesToInsert
        super.init(tableView: tableView, datasourceDelegate: datasourceDelegate, originalIndexPath: originalIndexPath)
    }
    
    //MARK: - table view datasource methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = datasourceDelegate.tableView(tableView, numberOfRowsInSection: section)
        return placeholderCell == nil ? count : count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var indexPathToUse = indexPath
        if let placeholderCell = self.placeholderCell {
            if indexPath == indexPathOfMovingItem {
                return placeholderCell
            }
            
            if indexPathOfMovingItem.row < (indexPath as NSIndexPath).row {
                indexPathToUse = IndexPath(row: (indexPath as NSIndexPath).row - 1, section: (indexPath as NSIndexPath).section)
            }
        }
        return datasourceDelegate.tableView(tableView, cellForRowAt: indexPathToUse)
    }
    
    override func persistChanges() throws {
        placeholderCell = nil
        
        tableView.deleteRows(at: [indexPathOfMovingItem], with: .none)
        
        guard let destinationSourceData = self.sourceData as? MutableAudioEntitySourceData where locationInDestinationTableView else {
            return
        }
        
        let noOfItemsToInsert = try destinationSourceData.insertEntities(entitiesToInsert, atIndexPath: indexPathOfMovingItem)
        let startingIndex = indexPathOfMovingItem.row
        
        var indexPaths = [IndexPath]()
        indexPaths.reserveCapacity(noOfItemsToInsert)
        for index in startingIndex ..< (startingIndex + noOfItemsToInsert)  {
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        
        tableView.insertRows(at: indexPaths, with: noOfItemsToInsert == 1 ? .fade : .automatic)

    }

}
