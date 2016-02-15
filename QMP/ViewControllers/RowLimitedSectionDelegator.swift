//
//  RowLimitedSectionDelegator.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/12/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

protocol RowLimitedSectionDelegatorDelegate : class {
    func willExpandOrCollapseSection()
}

final class RowLimitedSectionDelegator : AudioEntityDSDSectionDelegator {
	
    weak var delegate:RowLimitedSectionDelegatorDelegate?
    
    private unowned var tableView:UITableView
    private var tapGestureRecognizerHashToDSD = [Int:AudioEntityDSDProtocol]()
	private var expandedSection:AudioEntityDSDProtocol?
	
    init(datasourcesWithRowLimits: [(AudioEntityDSDProtocol, Int)], tableView:UITableView) {

        let datasources = datasourcesWithRowLimits.map() { (entry) -> AudioEntityDSDProtocol in
            let dataSource = entry.0
            dataSource.rowLimit = entry.1
            dataSource.rowLimitActive = true
            return dataSource
        }
        tableView.sectionHeaderHeight = ThemeHelper.tableViewSectionHeaderHeight
        self.tableView = tableView
		super.init(datasources: datasources)
	}
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return dsdSections.count
    }
	
	override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		guard let view = super.tableView(tableView, viewForHeaderInSection: section) as? SearchHeaderFooterView, headerView = view.headerView else {
			return nil
		}
        let datasourceDelegate = dsdSections[section]
		if dsdSections.count > 1 || expandedSection != nil {
			let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "didTapHeaderView:")
			headerView.addGestureRecognizer(tapGestureRecognizer)
			headerView.disclosureContainerView.hidden = false
			tapGestureRecognizerHashToDSD[tapGestureRecognizer.hashValue] = datasourceDelegate
		} else {
			headerView.disclosureContainerView.hidden = true
		}
		
		headerView.applyRotation(shouldExpand: expandedSection != nil && datasourceDelegate === expandedSection!)

		return view
	}
	
	override func reloadSections() {
		var newSections = [AudioEntityDSDProtocol]()
		if let expandedSection = self.expandedSection {
			newSections = [expandedSection]
		} else {
			newSections = originalOrderedDatasources.filter() {
                $0.rowLimitActive = true
                return $0.hasData
            }
            if newSections.count == 1 {
                newSections.first?.rowLimitActive = false
            }
		}
		dsdSections = newSections
	}
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        delegate?.willExpandOrCollapseSection()
    }
    
    func collapseAllSections() {
        expandedSection = nil
    }
	
	//MARK: tap gesture handler
	func didTapHeaderView(sender:UITapGestureRecognizer) {
		delegate?.willExpandOrCollapseSection()
		
		if let expandedSection = self.expandedSection {
			collapseSection(sender, dsdToCollapse: expandedSection)
		} else if let selectedSection = tapGestureRecognizerHashToDSD[sender.hashValue] {
			expandSection(sender, dsdToExpand: selectedSection)
		}
	}
    
    private func collapseSection(sender:UITapGestureRecognizer, dsdToCollapse:AudioEntityDSDProtocol) {
        (sender.view as? SearchResultsHeaderView)?.animateDisclosureIndicator(shouldExpand:false)
        expandedSection = nil
        
        let maxRows = dsdToCollapse.rowLimit
        let sourceDataCount = dsdToCollapse.sourceData.entities.count
        var reloadAllSections = false
        tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: 0 - tableView.contentInset.top), animated: true)
        tableView.beginUpdates()
        
        if maxRows < sourceDataCount {
            if sourceDataCount > 300 {
                reloadAllSections = true
            } else {
                var indexPaths = [NSIndexPath]()
                indexPaths.reserveCapacity(sourceDataCount - maxRows)
                for i in maxRows..<sourceDataCount {
                    indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
                }
                
                tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
            }
        }
        
        self.reloadSections()
        
        let indexSet = NSMutableIndexSet()
        for (i, dsd) in dsdSections.enumerate() {
            if dsd !== dsdToCollapse || reloadAllSections {
                indexSet.addIndex(i)
            }
        }
        

        if indexSet.count >= self.dsdSections.count {
            tableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        }
        tableView.insertSections(indexSet, withRowAnimation: .Automatic)
        tableView.endUpdates()
    }
	
    private func expandSection(sender:UITapGestureRecognizer, dsdToExpand:AudioEntityDSDProtocol) {
        (sender.view as? SearchResultsHeaderView)?.animateDisclosureIndicator(shouldExpand:true)
        tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: 0 - tableView.contentInset.top), animated: true)
        tableView.beginUpdates()
        
        let indexSet = NSMutableIndexSet()
        
        for (i, dsd) in dsdSections.enumerate() {
            if dsdToExpand !== dsd {
                indexSet.addIndex(i)
            }
        }
        expandedSection = dsdToExpand
        reloadSections()
    
        tableView.deleteSections(indexSet, withRowAnimation: .Automatic)
        
        dsdToExpand.rowLimitActive = false
        let maxRows = dsdToExpand.rowLimit
        
        let sourceDataCount = dsdToExpand.sourceData.entities.count
        if maxRows < sourceDataCount {
            var indexPaths = [NSIndexPath]()
            indexPaths.reserveCapacity(sourceDataCount - maxRows)
            for i in maxRows..<sourceDataCount {
                indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
            }
            tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        }
        
        tableView.endUpdates()

    }

}

