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
		ConstraintUtils.applyConstraintsToView(withAnchors: [.Left, .Top, .Right], subView: headerView, parentView: view)
		headerView.heightAnchor.constraintEqualToConstant(ThemeHelper.plainHeaderHight).active = true
		
		tableView.contentInset.top = ThemeHelper.plainHeaderHight
        tableView.scrollIndicatorInsets.top = ThemeHelper.plainHeaderHight
        tableView.contentOffset.y = -tableView.contentInset.top
        
		tableView.registerNib(NibContainer.mediaCollectionTableViewCellNib, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
		tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
		tableView.registerClass(SearchHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SearchResultsHeaderView.reuseIdentifier)
        
        
	}

}
