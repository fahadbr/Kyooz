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
    var message:String! {
        didSet {
            warningButton?.setTitle(message, forState: .Normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let label = warningButton.titleLabel else {
            return
        }
        label.textAlignment = NSTextAlignment.Center
        label.minimumScaleFactor = 0.6
        label.adjustsFontSizeToFitWidth = true
        label.allowsDefaultTighteningForTruncation = true
        label.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        label.numberOfLines = 2
        warningButton.setTitle(message, forState: .Normal)
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
