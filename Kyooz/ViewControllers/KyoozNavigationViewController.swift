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


final class KyoozNavigationViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
	
    private static let reuseIdentifier = "kyoozNavigationViewControllerCell"
    
    private let fadeOutAnimation = KyoozUtils.fadeOutAnimationWithDuration(0.4)
    
	private let tableView = UITableView(frame: CGRect.zero, style: .Grouped)
    
    private var cellConfigurations = [[CellConfiguration]]()

    private var blurView:UIVisualEffectView?
    private var initialLoadComplete = false
	
	private lazy var allMusicCellConfiguration:CellConfiguration = {
        let title = "HOME"
		let action = { () -> () in
			RootViewController.instance.libraryNavigationController.popToRootViewControllerAnimated(true)
		}
        return BasicCellConfiguration(name:title, action: action)
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
        let headerView = PlainHeaderView()
        headerView.effect = nil
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Top, .Left, .Right], subView: headerView, parentView: view)
        headerView.heightAnchor.constraintEqualToConstant(headerHeight).active = true

		ConstraintUtils.applyConstraintsToView(withAnchors: [.Left, .Right, .Bottom], subView: tableView, parentView: view)
        tableView.topAnchor.constraintEqualToAnchor(headerView.bottomAnchor).active = true
        tableView.separatorStyle = .SingleLine
		tableView.rowHeight = 50
        tableView.backgroundColor = UIColor.clearColor()
        tableView.registerClass(AbstractTableViewCell.self, forCellReuseIdentifier: KyoozNavigationViewController.reuseIdentifier)
        
        cellConfigurations.append([allMusicCellConfiguration])
        
        var section = [CellConfiguration]()
        for group in LibraryGrouping.otherGroupings {
            let title = group.name
            let action = {
                let vc = AudioEntityLibraryViewController()
                vc.sourceData = MediaQuerySourceData(filterQuery: group.baseQuery, libraryGrouping: group)
                vc.subGroups = [LibraryGrouping]()
                vc.title = title
                ContainerViewController.instance.pushViewController(vc)
            }
            section.append(BasicCellConfiguration(name: title, action: action))
        }
        
		cellConfigurations.append(section)
		
		cellConfigurations.append([settingsCellConfiguration])

		
		automaticallyAdjustsScrollViewInsets = false
		
		tableView.delegate = self
		tableView.dataSource = self
        
        let titleLabel = UILabel()
        titleLabel.text = "NAVIGATION"
        titleLabel.textColor = ThemeHelper.defaultFontColor
        titleLabel.font = UIFont(name: ThemeHelper.defaultFontNameBold, size: ThemeHelper.defaultFontSize)
        titleLabel.textAlignment = .Center
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Left, .Right, .Bottom], subView: titleLabel, parentView: headerView.contentView)
        titleLabel.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor).active = true
        
        let cancelButton = UIButton()
        cancelButton.setTitle("╳", forState: .Normal)
        cancelButton.setTitleColor(ThemeHelper.defaultFontColor, forState: .Normal)
        cancelButton.setTitleColor(ThemeHelper.defaultVividColor, forState: .Highlighted)
//        cancelButton.titleLabel?.font = UIFont.boldSystemFontOfSize(20)
        ConstraintUtils.applyConstraintsToView(withAnchors: [.Right, .Bottom], subView: cancelButton, parentView: headerView.contentView)
        cancelButton.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor).active = true
        cancelButton.widthAnchor.constraintEqualToAnchor(cancelButton.heightAnchor).active = true
        cancelButton.addTarget(self, action: #selector(self.transitionOut), forControlEvents: .TouchUpInside)
	}
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        animateCells()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let blurView = UIVisualEffectView()
        self.blurView = blurView
        ConstraintUtils.applyStandardConstraintsToView(subView: blurView, parentView: view)
        view.sendSubviewToBack(blurView)
        UIView.animateWithDuration(0.35, delay: 0, options: .CurveEaseIn, animations: {
            blurView.effect = UIBlurEffect(style: .Dark)
        }, completion: nil)
    }
    
    private func animateCells() {
        var delay:Double = 0
        for cell in tableView.visibleCells {
            cell.alpha = 0
            cell.contentView.alpha = 1
            UIView.animateWithDuration(0.35, delay: delay, options: .CurveEaseOut, animations: {
                cell.alpha = 1
                }, completion: nil)
            delay += 0.05
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
        cell.textLabel?.textColor = ThemeHelper.defaultFontColor
        if !initialLoadComplete {
            cell.contentView.alpha = 0
        }
		cell.backgroundColor = UIColor.clearColor()
        
        //upon loading the last cell, trigger the cell animations
        if indexPath.section == cellConfigurations.count - 1 && indexPath.row == cellConfigurations[indexPath.section].count - 1 && !initialLoadComplete {
            initialLoadComplete = true
            KyoozUtils.doInMainQueueAsync(animateCells)
        }

		return cell
	}

	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        let cellConfiguration = cellConfigurations[indexPath.section][indexPath.row]
		
        cellConfiguration.action()
        
        transitionOut()
	}
    
    func transitionOut() {
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
