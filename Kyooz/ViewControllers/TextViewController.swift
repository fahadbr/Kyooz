//
//  TextViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/8/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class TextViewController: UIViewController {
    
    let textView:UITextView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeHelper.defaultTableCellColor
        
        ConstraintUtils.applyStandardConstraintsToView(subView: textView, parentView: view)

        textView.backgroundColor = ThemeHelper.defaultTableCellColor
        textView.textColor = ThemeHelper.defaultFontColor
        
        func flexibleSpace() -> UIBarButtonItem {
            return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        }
        let dismissButton = UIBarButtonItem(title: "Dismiss", style: .Done, target: self, action: #selector(self.dismiss))
        dismissButton.tintColor = ThemeHelper.defaultTintColor
        toolbarItems = [flexibleSpace(), dismissButton, flexibleSpace()]
        navigationController?.toolbarHidden = false
    }
    
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
