//
//  AbstractViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/9/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

class AbstractViewController : UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: RootViewController.instance, action: "activateSearch")
    }
    
}

class AbstractTableViewController : UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: RootViewController.instance, action: "activateSearch")
    }
    
}