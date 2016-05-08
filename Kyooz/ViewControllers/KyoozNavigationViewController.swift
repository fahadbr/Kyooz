//
//  LibraryHomeViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/19/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

private protocol CellConfiguration {
    var name:String { get }
    var action:()->() { get }
}

private struct BasicCellConfiguration : CellConfiguration {
    let name:String
    let action:()->()
}

private class ViewSwitcher : CellConfiguration {
    
    let name: String
    let viewControllerGeneratingBlock:()->UIViewController
    var isSelected:Bool = false
    var viewControllers:[UIViewController]?
    
    var action:()->() {
        return setVCs
    }
    
    init(name:String, viewControllerGeneratingBlock:()->UIViewController) {
        self.name = name
        self.viewControllerGeneratingBlock = viewControllerGeneratingBlock
    }
    
    func setVCs() {
        if isSelected {
            RootViewController.instance.libraryNavigationController.popToRootViewControllerAnimated(true)
        } else if let vcs = viewControllers {
            RootViewController.instance.libraryNavigationController.setViewControllers(vcs, animated: false)
        } else {
            RootViewController.instance.libraryNavigationController.setViewControllers([viewControllerGeneratingBlock()], animated: false)
        }
        
        isSelected = true
    }
    
    func recallVCs() {
//        viewControllers = RootViewController.instance.libraryNavigationController.viewControllers
        isSelected = false
    }
    
    
}

final class KyoozNavigationViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	private static let fadeInAnimation = KyoozUtils.fadeInAnimationWithDuration(0.35)
    private static let reuseIdentifier = "kyoozNavigationViewControllerCell"
    
    private let fadeOutAnimation = KyoozUtils.fadeOutAnimationWithDuration(0.4)
    
	private let tableView = UITableView(frame: CGRect.zero, style: .Grouped)
	
    private var cellConfigurations = [[CellConfiguration]]()
    private var selectedIndexPath:NSIndexPath = NSIndexPath(forRow: 0, inSection: 0) {
        willSet {
            if newValue != selectedIndexPath {
                (cellConfigurations[selectedIndexPath.section][selectedIndexPath.row] as? ViewSwitcher)?.recallVCs()
            }
        }
    }
    
    private var delay:Double = 0
    private var blurView:UIVisualEffectView?
	
	private lazy var allMusicCellConfiguration:CellConfiguration = {
        let title = "ALL MUSIC"
		let action = { () -> UIViewController in
			let vc = AudioEntityLibraryViewController()
			vc.title = title
            let baseGroupIndex = NSUserDefaults.standardUserDefaults().integerForKey(UserDefaultKeys.AllMusicBaseGroup)
            let selectedGroup = LibraryGrouping.allMusicGroupings[baseGroupIndex]
            vc.sourceData = MediaQuerySourceData(filterQuery: selectedGroup.baseQuery, libraryGrouping: selectedGroup)
			return vc
		}
        let vs = ViewSwitcher(name: title, viewControllerGeneratingBlock: action)
        return vs
	}()
	
	private lazy var settingsCellConfiguration:CellConfiguration = {
		let action = {
			ContainerViewController.instance.presentViewController(UIStoryboard.settingsViewController(), animated: true, completion: nil)
		}
		return BasicCellConfiguration(name:"SETTINGS", action: action)
	}()
	
	override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clearColor()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        fadeOutAnimation.delegate = self
		let headerHeight:CGFloat = ThemeHelper.plainHeaderHight

		ConstraintUtils.applyStandardConstraintsToView(subView: tableView, parentView: view)
        tableView.scrollsToTop = false
        tableView.separatorStyle = .SingleLine
		tableView.contentInset.top = headerHeight
		tableView.scrollIndicatorInsets.top = headerHeight
		tableView.rowHeight = 50
		tableView.panGestureRecognizer.requireGestureRecognizerToFail(ContainerViewController.instance.centerPanelPanGestureRecognizer)
        tableView.backgroundColor = UIColor.clearColor()
        tableView.registerClass(AbstractTableViewCell.self, forCellReuseIdentifier: KyoozNavigationViewController.reuseIdentifier)
		
        var section = [allMusicCellConfiguration]
        for group in LibraryGrouping.otherGroupings {
            let title = group.name
            let action = { () -> UIViewController in
                let vc = AudioEntityLibraryViewController()
                vc.sourceData = MediaQuerySourceData(filterQuery: group.baseQuery, libraryGrouping: group)
                vc.subGroups = [LibraryGrouping]()
                vc.title = title
                return vc
            }
            section.append(ViewSwitcher(name: title, viewControllerGeneratingBlock: action))
        }
        
		cellConfigurations.append(section)
		
		cellConfigurations.append([settingsCellConfiguration])
        
        let cancelConfig = BasicCellConfiguration(name: "CANCEL", action: {
            //no op
        })
        cellConfigurations.append([cancelConfig])
		
		let headerView = PlainHeaderView()
        headerView.effect = nil
		ConstraintUtils.applyConstraintsToView(withAnchors: [.Top, .Left, .Right], subView: headerView, parentView: view)
		headerView.heightAnchor.constraintEqualToConstant(headerHeight).active = true
		
		automaticallyAdjustsScrollViewInsets = false
		
		tableView.delegate = self
		tableView.dataSource = self
        
        title = "LIBRARY"
	}
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        delay = 0
        tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let blurView = UIVisualEffectView()
        self.blurView = blurView
        ConstraintUtils.applyStandardConstraintsToView(subView: blurView, parentView: view)
        view.sendSubviewToBack(blurView)
        UIView.animateWithDuration(0.3) { 
            blurView.effect = UIBlurEffect(style: .Dark)
        }
    }

    
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return cellConfigurations.count
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return cellConfigurations[section].count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(KyoozNavigationViewController.reuseIdentifier) ?? AbstractTableViewCell()
		cell.textLabel?.text = cellConfigurations[indexPath.section][indexPath.row].name
		cell.textLabel?.font = ThemeHelper.defaultFont
        cell.textLabel?.textColor = indexPath == selectedIndexPath ? ThemeHelper.defaultVividColor : ThemeHelper.defaultFontColor
		cell.backgroundColor = UIColor.clearColor()
        cell.alpha = 0
        UIView.animateWithDuration(0.35, delay: delay, options: .CurveEaseOut, animations: { 
            cell.alpha = 1
        }, completion: nil)
        delay += 0.05
        
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let cellConfiguration = cellConfigurations[indexPath.section][indexPath.row]
        if cellConfiguration is ViewSwitcher {
            selectedIndexPath = indexPath
        }
		
        cellConfiguration.action()
        ContainerViewController.instance.longPressGestureRecognizer.enabled = true
        view.layer.addAnimation(fadeOutAnimation, forKey: nil)
	}
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        blurView?.removeFromSuperview()
        blurView = nil
        view.layer.removeAllAnimations()
        view.removeFromSuperview()
        removeFromParentViewController()
    }
}
