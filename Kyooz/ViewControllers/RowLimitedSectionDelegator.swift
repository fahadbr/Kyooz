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
    func didExpandOrCollapseSection()
}

final class RowLimitedSectionDelegator : AudioEntityDSDSectionDelegator {
	
    weak var delegate:RowLimitedSectionDelegatorDelegate?
    
    private weak var tableView:UITableView!

    private var tapGestureRecognizers = [UITapGestureRecognizer]()
	private var expandedSection:AudioEntityDSDProtocol?
    
    private var otherSectionsHaveData:Bool {
        for dsd in originalOrderedDatasources {
            if dsd !== expandedSection && dsd.hasData { return true }
        }
        return false
    }
	
    init(datasourceDelegates: [AudioEntityDSDProtocol], tableView:UITableView) {
        tableView.sectionHeaderHeight = ThemeHelper.tableViewSectionHeaderHeight
        self.tableView = tableView
		super.init(datasources: datasourceDelegates)
	}
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dsdSections.count
    }
	
	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: RowLimitedSectionHeaderView.reuseIdentifier) as? RowLimitedSectionHeaderView else {
			return nil
		}
		
		
        let datasourceDelegate = dsdSections[section]
		if dsdSections.count > 1 || (expandedSection != nil && otherSectionsHaveData){
			let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didTapHeaderView(_:)))
			headerView.addGestureRecognizer(tapGestureRecognizer)
			headerView.disclosureView.isHidden = false
            headerView.isUserInteractionEnabled = true
            if tapGestureRecognizers.count - 1 < section {
                tapGestureRecognizers.append(tapGestureRecognizer)
            } else {
                tapGestureRecognizers[section] = tapGestureRecognizer
            }
            
		} else {
			headerView.disclosureView.isHidden = true
            headerView.isUserInteractionEnabled = false
		}
        
        if let sourceData = datasourceDelegate.sourceData as? SearchResultsSourceData
            , sourceData.searchExecutionController.searchInProgress {
            
            if !headerView.activityIndicator.isAnimating {
                headerView.activityIndicator.startAnimating()
            }
        } else {
            if headerView.activityIndicator.isAnimating {
                headerView.activityIndicator.stopAnimating()
            }
        }
		
		let headerViewText = sourceData.sections[section].name
		let subText = "\(datasourceDelegate.sourceData.entities.count) TOTAL"
		headerView.setLabelText(headerViewText, subText: subText)
		
		headerView.expanded = datasourceDelegate === expandedSection

		return headerView
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
    
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.willExpandOrCollapseSection()
    }
    
    func collapseAllSections() {
        expandedSection = nil
    }
	
	//MARK: tap gesture handler
	func didTapHeaderView(_ sender:UITapGestureRecognizer) {
		delegate?.willExpandOrCollapseSection()
		
		if let expandedSection = self.expandedSection {
			collapseSection(sender, dsdToCollapse: expandedSection)
		} else if let selectedSection = tapGestureRecognizers.index(of: sender) {
			expandSection(sender, dsdToExpand: dsdSections[selectedSection])
		}
        
        delegate?.didExpandOrCollapseSection()
	}
    
    private func collapseSection(_ sender:UITapGestureRecognizer, dsdToCollapse:AudioEntityDSDProtocol) {
        (sender.view as? RowLimitedSectionHeaderView)?.setExpanded(expanded: false, animated: true)
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
                var indexPaths = [IndexPath]()
                indexPaths.reserveCapacity(sourceDataCount - maxRows)
                for i in maxRows..<sourceDataCount {
                    indexPaths.append(IndexPath(row: i, section: 0))
                }
                
                tableView.deleteRows(at: indexPaths, with: .automatic)
            }
        }
        
        reloadSections()
        
        let indexSet = NSMutableIndexSet()
        for (i, dsd) in dsdSections.enumerated() {
            if dsd !== dsdToCollapse || reloadAllSections {
                indexSet.add(i)
            }
        }
        

        if indexSet.count >= self.dsdSections.count {
            tableView.deleteSections(IndexSet(integer: 0), with: .automatic)
        }
        tableView.insertSections(indexSet as IndexSet, with: .automatic)
        tableView.endUpdates()
    }
	
    private func expandSection(_ sender:UITapGestureRecognizer, dsdToExpand:AudioEntityDSDProtocol) {
        (sender.view as? RowLimitedSectionHeaderView)?.setExpanded(expanded: true, animated: true)
        tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: 0 - tableView.contentInset.top), animated: true)
        tableView.beginUpdates()
        
        let indexSet = NSMutableIndexSet()
        
        for (i, dsd) in dsdSections.enumerated() {
            if dsdToExpand !== dsd {
                indexSet.add(i)
            }
        }
        expandedSection = dsdToExpand
        reloadSections()
    
        tableView.deleteSections(indexSet as IndexSet, with: .automatic)
        
        dsdToExpand.rowLimitActive = false
        let maxRows = dsdToExpand.rowLimit
        
        let sourceDataCount = dsdToExpand.sourceData.entities.count
        if maxRows < sourceDataCount {
            var indexPaths = [IndexPath]()
            indexPaths.reserveCapacity(sourceDataCount - maxRows)
            for i in maxRows..<sourceDataCount {
                indexPaths.append(IndexPath(row: i, section: 0))
            }
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
        
        tableView.endUpdates()

    }

}

