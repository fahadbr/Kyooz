//
//  TestTableViewDataSource.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/1/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class TestTableViewDataSourceDelegate: NSObject, UITableViewDataSource, UITableViewDelegate{
    
    let sections = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    var mediaEntityTVC:AbstractMediaEntityTableViewController?

    //MARK: - DATASOUCE
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.characters.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(MediaCollectionTableViewCell.reuseIdentifier) else {
            return UITableViewCell()
        }
        cell.textLabel?.text = "Row \(indexPath.row)"
        cell.detailTextLabel?.text = "Section \(indexPath.section)"
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        Logger.debug("selected row \(indexPath.row) in section \(indexPath.section)")
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return sections.characters.map() { String($0)}
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        KyoozUtils.doInMainQueueAsync() { [weak self] in self?.mediaEntityTVC?.synchronizeOffsetWithScrollview(tableView) }
        return index
    }
    //MARK: - DELEGATE
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let view = NSBundle.mainBundle().loadNibNamed("SearchResultsHeaderView", owner: self, options: nil)?.first as? SearchResultsHeaderView else {
            return nil
        }
        view.headerTitleLabel.text = sections[section]
        view.disclosureContainerView.hidden = true
        return view
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}
