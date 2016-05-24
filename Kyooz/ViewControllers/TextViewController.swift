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
    var showDimissButton = true

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeHelper.defaultTableCellColor
        
        ConstraintUtils.applyStandardConstraintsToView(subView: textView, parentView: view)
        
        textView.editable = false
        textView.backgroundColor = ThemeHelper.defaultTableCellColor
        textView.textColor = ThemeHelper.defaultFontColor
        
        guard showDimissButton else { return }
        
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
    
    func loadHtmlFile(withName name:String) throws {
        var d:NSDictionary? = nil
        guard let htmlFilePath = NSBundle.mainBundle().URLForResource(name, withExtension: "html") else {
            throw KyoozError(errorDescription:"no file named \(name).html exists")
        }
        
        guard let string = try? NSAttributedString(URL: htmlFilePath, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: &d) else {
            throw KyoozError(errorDescription:"could not load file \(name).html")
        }
        
        textView.attributedText = string
    }
}
