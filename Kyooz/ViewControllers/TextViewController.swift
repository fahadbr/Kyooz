//
//  TextViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/8/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class TextViewController: UIViewController {
    
    let textView:UITextView
	let showDismissButton:Bool
	
	init(fileName:String, documentType:DocumentType, showDismissButton:Bool = false) throws {
		self.textView = try UITextView(fileName: fileName, documentType: documentType)
		self.showDismissButton = showDismissButton
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func loadView() {
		view = textView
	}
	

    override func viewDidLoad() {
        super.viewDidLoad()
		
        guard showDismissButton else { return }
        

        let dismissButton = UIBarButtonItem(title: "DISMISS",
                                            style: .Done,
                                            target: self,
                                            action: #selector(self.dismiss))
		
        dismissButton.tintColor = ThemeHelper.defaultTintColor
        toolbarItems = [UIBarButtonItem.flexibleSpace(), dismissButton, UIBarButtonItem.flexibleSpace()]
        navigationController?.toolbarHidden = false
    }
    
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
	
}
