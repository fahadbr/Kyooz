//
//  AudioEntityPlainHeaderViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/29/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class AudioEntityPlainHeaderViewController: AudioEntityViewController {
	
	let headerView = PlainHeaderView()

	override func viewDidLoad() {
		super.viewDidLoad()
		ConstraintUtils.applyConstraintsToView(withAnchors: [.left, .top, .right], subView: headerView, parentView: view)
		headerView.heightAnchor.constraint(equalToConstant: ThemeHelper.plainHeaderHight).isActive = true
		
		tableView.contentInset.top = ThemeHelper.plainHeaderHight
        tableView.scrollIndicatorInsets.top = ThemeHelper.plainHeaderHight
        tableView.contentOffset.y = -tableView.contentInset.top
        
        
	}

}
