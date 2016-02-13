//
//  RowLimitedSectionDelegator.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/12/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class RowLimitSectionDelegator : AudioEntityDSDSectionDelegator {

	private class RowLimit {
		let limit:Int
		var isExpanded:Bool = false
		init(limit:Int) {
			self.limit = limit
		}
	}
	
	private var rowLimitBySection:[RowLimit]
	private var tapGestureRecognizers = [UITapGestureRecognizer]()
	private var expandedSection:Int?
	
	init(datasourcesWithRowLimits: [(AudioEntityDSDProtocol, Int)]) {
		let datasources = datasourcesWithRowLimits.map() { return $0.0 }
		rowLimitBySection = datasourcesWithRowLimits.map() { return RowLimit(limit: $0.1) }
		super.init(datasources: datasources)
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let actualRows = super.tableView(tableView, numberOfRowsInSection: section)
		let rowLimit = rowLimitBySection[section]
		
		if rowLimit.isExpanded {
			return actualRows
		}
		return min(actualRows, rowLimit.limit)
		
	}
	
	override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		guard let view = super.tableView(tableView, viewForHeaderInSection: section) as? SearchHeaderFooterView, headerView = view.headerView else {
			return nil
		}
		if dsdSections.count > 1 {
			let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "didTapHeaderView:")
			headerView.addGestureRecognizer(tapGestureRecognizer)
			headerView.disclosureContainerView.hidden = false
			tapGestureRecognizers[section] = tapGestureRecognizer
		} else {
			headerView.disclosureContainerView.hidden = true
		}
		
		headerView.applyRotation(shouldExpand: expandedSection != nil && section == expandedSection!)

		return view
	}
	
	override func reloadSections() {
		var newSections = [AudioEntityDSDProtocol]()
		if let expandedSection = self.expandedSection {
			newSections = [originalOrderedDatasources[expandedSection]]
		} else {
			newSections = originalOrderedDatasources.filter() { $0.hasData }
			rowLimitBySection.forEach() { $0.isExpanded = false }
			if newSections.count == 1 {
				rowLimitBySection[0]?.isExpanded = true
			}
		}
		sections = newSections
	}
	
	//MARK: tap gesture handler
	func didTapHeaderView(sender:UITapGestureRecognizer) {
		searchController.searchBar.resignFirstResponder()
		
		if let se = self.selectedHeader {
			self.collapseSelectedSectionAndInsertSections(sender, selectedHeader: se)
		} else if let se = searchExecutionControllers.filter({ self.tapGestureRecognizers[$0.libraryGroup] === sender }).first {
			self.removeSectionsAndExpandSelectedSection(sender, searchExecutor: se)
		}
	}
	
	private func collapseSelectedSectionAndInsertSections(sender:UITapGestureRecognizer, selectedHeader:SearchExecutionController<AudioEntity>) {
		(sender.view as? SearchResultsHeaderView)?.animateDisclosureIndicator(shouldExpand:false)
		self.selectedHeader = nil
		
		let rowLimit = rowLimitPerSection[selectedHeader.libraryGroup]!
		let maxRows = rowLimit.limit
		rowLimit.isExpanded = false
		
		let currentNoOfRows = selectedHeader.searchResults.count
		var reloadAllSections = false
		//reduce the number of rows in the tableView to be equal to maxRows
		if maxRows < currentNoOfRows {
			if currentNoOfRows > 300 {
				reloadAllSections = true
			} else {
				var indexPaths = [NSIndexPath]()
				for i in maxRows..<currentNoOfRows {
					indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
				}
				
				self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
			}
		}
		
		self.reloadSections()
		
		let indexSet = NSMutableIndexSet()
		for i in 0..<self.sections.count {
			if self.sections[i] !== selectedHeader || reloadAllSections {
				indexSet.addIndex(i)
			}
		}
		
		tableView.beginUpdates()
		if indexSet.count >= self.sections.count {
			self.tableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
		}
		tableView.insertSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic)
		tableView.endUpdates()
	}
	
	private func removeSectionsAndExpandSelectedSection(sender:UITapGestureRecognizer, searchExecutor:SearchExecutionController<AudioEntity>) {
		(sender.view as? SearchResultsHeaderView)?.animateDisclosureIndicator(shouldExpand:true)
		
		let indexSet = NSMutableIndexSet()
		
		for i in 0..<self.sections.count {
			if searchExecutor !== self.sections[i] {
				indexSet.addIndex(i)
			}
		}
		self.sections = [searchExecutor]
		self.tableView.deleteSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic)
		
		self.selectedHeader = searchExecutor
		
		let searchResults = searchExecutor.searchResults
		let rowLimit = rowLimitPerSection[searchExecutor.libraryGroup]!
		
		rowLimit.isExpanded = true
		let maxRows = rowLimit.limit
		
		if searchResults.count > maxRows {
			var indexPaths = [NSIndexPath]()
			for i in maxRows..<searchResults.count {
				indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
			}
			self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
		}
	}

}

