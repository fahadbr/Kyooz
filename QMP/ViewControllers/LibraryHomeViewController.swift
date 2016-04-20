//
//  LibraryHomeViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/19/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class LibraryHomeViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	typealias CellConfiguration = (name:String, action:()->())
	private let tableView = UITableView(frame: CGRect.zero, style: .Grouped)
	
	private var cellConfigurations = [[CellConfiguration]]()
	
	private lazy var allMusicCellConfiguration:CellConfiguration = {
        let title = "ALL MUSIC"
		let action = {
			let vc = AudioEntityLibraryViewController()
			vc.title = title
			ContainerViewController.instance.pushViewController(vc)
		}
		return (title, action)
	}()
	
	private lazy var settingsCellConfiguration:CellConfiguration = {
		let action = {
			ContainerViewController.instance.presentViewController(UIStoryboard.settingsViewController(), animated: true, completion: nil)
		}
		return ("SETTINGS", action)
	}()
	
	override func viewDidLoad() {
		let headerHeight:CGFloat = 65

		ConstraintUtils.applyStandardConstraintsToView(subView: tableView, parentView: view)
		tableView.contentInset.top = headerHeight
		tableView.scrollIndicatorInsets.top = headerHeight
		tableView.rowHeight = 50
		
        var section = [allMusicCellConfiguration]
        for group in LibraryGrouping.otherGroupings {
            let title = group.name
            let action = {
                let vc = AudioEntityLibraryViewController()
                vc.sourceData = MediaQuerySourceData(filterQuery: group.baseQuery, libraryGrouping: group)
                vc.subGroups = [LibraryGrouping]()
                vc.title = title
                ContainerViewController.instance.pushViewController(vc)
            }
            section.append((title, action))
        }
        
		cellConfigurations.append(section)
		
		cellConfigurations.append([settingsCellConfiguration])
		
		let headerVC = UIStoryboard.utilHeaderViewController()
		ConstraintUtils.applyConstraintsToView(withAnchors: [.Top, .Left, .Right], subView: headerVC.view, parentView: view)
		headerVC.view.heightAnchor.constraintEqualToConstant(headerHeight).active = true
		addChildViewController(headerVC)
		headerVC.didMoveToParentViewController(self)
		
		automaticallyAdjustsScrollViewInsets = false
		
		tableView.delegate = self
		tableView.dataSource = self
        
        title = "LIBRARY"
	}
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return cellConfigurations.count
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return cellConfigurations[section].count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = UITableViewCell()
		cell.textLabel?.text = cellConfigurations[indexPath.section][indexPath.row].name
		cell.textLabel?.font = ThemeHelper.defaultFont
		cell.textLabel?.textColor = ThemeHelper.defaultFontColor
		
		if indexPath.section < cellConfigurations.count - 1 {
			cell.accessoryType = .DisclosureIndicator
		}
		
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		cellConfigurations[indexPath.section][indexPath.row].action()
	}
}