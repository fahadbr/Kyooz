//
//  AudioEntityViewControllerProtocol.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/15/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

protocol AudioEntityViewControllerProtocol {
    
    var tableView:UITableView { get }
    
	var sourceData:AudioEntitySourceData { get }
}
