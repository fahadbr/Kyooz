//
//  WarningViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/12/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class WarningViewController: UIViewController {

    @IBOutlet var warningButton: UIButton!
    var handler:(()->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        warningButton.titleLabel?.textAlignment = NSTextAlignment.Center
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func executeHandler(sender: UIButton) {
        handler?()
    }

}
