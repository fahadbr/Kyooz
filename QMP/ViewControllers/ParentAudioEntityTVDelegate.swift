//
//  ParentAudioEntityTVDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class ParentAudioEntityTVDelegate : NSObject, UITableViewDelegate {
    
    var sourceData:AudioEntitySourceData
    
    init(sourceData:AudioEntitySourceData) {
        self.sourceData = sourceData
        super.init()
    }
    
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SearchResultsHeaderView.reuseIdentifier) as? SearchHeaderFooterView else {
            return nil
        }
        view.initializeHeaderView()
        
        if let headerView = view.headerView {
            headerView.headerTitleLabel.text = sourceData.sectionNames?[section]
            headerView.disclosureContainerView.hidden = true
        }
        return view
    }
    
}
