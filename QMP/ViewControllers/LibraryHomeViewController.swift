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
            let baseGroupIndex = NSUserDefaults.standardUserDefaults().integerForKey(UserDefaultKeys.AllMusicBaseGroup)
            let selectedGroup = LibraryGrouping.allMusicGroupings[baseGroupIndex]
            vc.sourceData = MediaQuerySourceData(filterQuery: selectedGroup.baseQuery, libraryGrouping: selectedGroup)
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
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
		let headerHeight:CGFloat = ThemeHelper.plainHeaderHight

		ConstraintUtils.applyStandardConstraintsToView(subView: tableView, parentView: view)
        tableView.scrollsToTop = false
        tableView.separatorStyle = .SingleLine
		tableView.contentInset.top = headerHeight
		tableView.scrollIndicatorInsets.top = headerHeight
		tableView.rowHeight = 50
		tableView.panGestureRecognizer.requireGestureRecognizerToFail(ContainerViewController.instance.centerPanelPanGestureRecognizer)
		tableView.backgroundColor = UIColor.blackColor()
		
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
		
		let headerView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
		ConstraintUtils.applyConstraintsToView(withAnchors: [.Top, .Left, .Right], subView: headerView, parentView: view)
		headerView.heightAnchor.constraintEqualToConstant(headerHeight).active = true
		ThemeHelper.applyBottomShadowToView(headerView)
        
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
		let cell = AbstractTableViewCell()
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
