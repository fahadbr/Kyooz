//
//  SectionedTVDataSourceDelegator.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/3/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class SectionedTVDataSourceDelegator : NSObject, UITableViewDataSource {
	
	private let originalOrderedDatasources:[AudioEntityTVDataSourceProtocol]
	private var sections:[AudioEntityTVDataSourceProtocol] = [AudioEntityTVDataSourceProtocol]()
	
	init(datasources:[AudioEntityTVDataSourceProtocol]) {
		self.originalOrderedDatasources = datasources
	}
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return sections.count
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sections[section].tableView(tableView, numberOfRowsInSection: 0)
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return sections[indexPath.section].tableView(tableView, cellForRowAtIndexPath: indexPath)
	}
	
	private func reloadSections() {
		sections = originalOrderedDatasources.filter() {
			return $0.hasData
		}
	}
	
}