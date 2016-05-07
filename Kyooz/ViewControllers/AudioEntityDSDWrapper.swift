//
//  AudioEntityDSDWrapper.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/19/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class AudioEntityDSDWrapper : NSObject, AudioEntityDSDProtocol {
    
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
    
    let datasourceDelegate:AudioEntityDSDProtocol

    init(sourceDSD:AudioEntityDSDProtocol) {
        datasourceDelegate = sourceDSD
        super.init()
    }
    
    //MARK: - table view datasource methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasourceDelegate.tableView(tableView, numberOfRowsInSection: section)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return datasourceDelegate.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return datasourceDelegate.tableView?(tableView, canMoveRowAtIndexPath: indexPath) ?? false
    }
    
}