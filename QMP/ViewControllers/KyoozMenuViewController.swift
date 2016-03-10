//
//  KyoozMenuViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/9/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class KyoozMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	let tableView = UITableView()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		ViewUtils.applyStandardConstraintsToView(subView: tableView, parentView: view)
		tableView.rowHeight = 40
		tableView.layer.cornerRadius = 15
		tableView.registerClass(KyoozMenuCell.self, forCellReuseIdentifier: KyoozMenuCell.reuseIdentifier)
		
    }
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return UITableViewCell()
	}
	


}

private final class KyoozMenuCell : UITableViewCell {
	
	static let reuseIdentifier = "kyoozMenuCell"
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}
	
	func initialize() {
		textLabel?.font = ThemeHelper.defaultFont
	}
	
}
