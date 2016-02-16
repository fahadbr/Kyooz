//
//  DragAndDropDSDWrapper.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/15/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

//this class cannot be used with multisection datasources
final class DragAndDropDSDWrapper: NSObject, AudioEntityDSDProtocol {

    var rowLimit:Int {
        get {
            return datasourceDelegate.rowLimit
        } set {
            datasourceDelegate.rowLimit = newValue
        }
    }
    
    var rowLimitActive:Bool {
        get {
            return datasourceDelegate.rowLimitActive
        } set {
            datasourceDelegate.rowLimitActive = newValue
        }
    }
    
    var hasData:Bool {
        return datasourceDelegate.hasData
    }
    
    var sourceData:AudioEntitySourceData {
        return datasourceDelegate.sourceData
    }
    
    var datasourceDelegate:AudioEntityDSDProtocol
    var endingInsert:Bool = false
    var indexPathOfMovingItem:NSIndexPath! {
        didSet {
            if indexPathOfMovingItem == nil { return }
            if indexPathOfMovingItem.row == sourceData.entities.count || indexPathOfMovingItem.row == 0 {
                placeholderCell.hidden = false
            } else {
                placeholderCell.hidden = true
            }
        }
    }
    
    var placeholderCell:UITableViewCell = {
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
    
    init(datasourceDelegate:AudioEntityDSDProtocol) {
        self.datasourceDelegate = datasourceDelegate
    }
    
    //MARK: - table view datasource methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = datasourceDelegate.tableView(tableView, numberOfRowsInSection: section)
        return endingInsert ? count : count + 1
    }
    
    func tableView(tableView: UITableView, var cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if !endingInsert {
            if indexPath == indexPathOfMovingItem {
                return placeholderCell
            }
            
            if indexPathOfMovingItem.row < indexPath.row {
                indexPath = NSIndexPath(forRow: indexPath.row - 1, inSection: indexPath.section)
            }
        }
        return datasourceDelegate.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return datasourceDelegate.tableView?(tableView, canMoveRowAtIndexPath: indexPath) ?? false
    }

}
