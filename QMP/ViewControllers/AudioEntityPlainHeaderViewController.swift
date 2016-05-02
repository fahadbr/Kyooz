//
//  AudioEntityPlainHeaderViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/29/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class AudioEntityPlainHeaderViewController: AudioEntityViewController {
	
	class var headerHeight:CGFloat {
		return 65
	}
	
	let headerView = PlainHeaderView()

	override func viewDidLoad() {
		super.viewDidLoad()
		ConstraintUtils.applyConstraintsToView(withAnchors: [.Left, .Top, .Right], subView: headerView, parentView: view)
		headerView.heightAnchor.constraintEqualToConstant(self.dynamicType.headerHeight).active = true
		
		tableView.contentInset.top = self.dynamicType.headerHeight
		tableView.scrollIndicatorInsets.top = self.dynamicType.headerHeight
		tableView.registerNib(NibContainer.mediaCollectionTableViewCellNib, forCellReuseIdentifier: MediaCollectionTableViewCell.reuseIdentifier)
		tableView.registerNib(NibContainer.imageTableViewCellNib, forCellReuseIdentifier: ImageTableViewCell.reuseIdentifier)
		tableView.registerClass(SearchHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SearchResultsHeaderView.reuseIdentifier)
        
        
	}

}
