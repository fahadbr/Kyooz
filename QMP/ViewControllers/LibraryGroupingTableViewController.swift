//
//  LibraryGroupingTableViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 10/4/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class LibraryGroupingTableViewController: AbstractTableViewController {
    
    private let tableViewCellIdentifier = "libraryGroupingCell"
    private let font = UIFont(name: ThemeHelper.defaultFontName, size: ThemeHelper.defaultFontSize * 1.10)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Music Library"
    }

    // MARK: - Table view data source



    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LibraryGrouping.values.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(tableViewCellIdentifier) else {
            Logger.error("couldnt find cell with reuse identifier \(tableViewCellIdentifier)")
            return UITableViewCell()
        }
        
        let index = indexPath.row
        let groupings = LibraryGrouping.values
        guard groupings.count > index else {
            Logger.error("Trying to access grouping index larger than available.  Array count is \(groupings.count) but trying to access \(index)")
            return UITableViewCell()
        }
        
        cell.textLabel?.text = groupings[index].name
        cell.textLabel?.font = self.font
        cell.textLabel?.textColor = ThemeHelper.defaultFontColor
        
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let vc = UIStoryboard.mediaEntityTableViewController()
        vc.libraryGroupingType = LibraryGrouping.values[indexPath.row]
        vc.filterQuery = vc.libraryGroupingType.baseQuery.setMusicOnly().shouldQueryCloudItems(true)
        vc.title = vc.libraryGroupingType.name
        
        navigationController?.pushViewController(vc, animated: true)
    }

}
