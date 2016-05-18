//
//  AudioEntityTableViewDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/9/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class AudioEntityTableViewDelegate : NSObject, UITableViewDelegate {
    var sourceData:AudioEntitySourceData
    
    init(sourceData:AudioEntitySourceData) {
        self.sourceData = sourceData
        super.init()
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SearchResultsHeaderView.reuseIdentifier) as? SearchHeaderFooterView else {
            return nil
        }
        
        let headerView = view.headerView
		headerView.headerTitleLabel.text = sourceData.sections[section].name
		headerView.disclosureContainerView.hidden = true
        return view
    }
}