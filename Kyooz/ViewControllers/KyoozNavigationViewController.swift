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

private struct SectionConfiguration {
	let sectionName:String
	let cellConfigurations:[CellConfiguration]
	var count:Int { return cellConfigurations.count }
	subscript(i:Int) -> CellConfiguration {
		return cellConfigurations[i]
	}
}


final class KyoozNavigationViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
	
    private static let reuseIdentifier = "kyoozNavigationViewControllerCell"
    
    private let fadeOutAnimation = KyoozUtils.fadeOutAnimationWithDuration(0.4)
    
	private let tableView = UITableView(frame: CGRect.zero, style: .Grouped)
    
    private var sectionConfigurations = [SectionConfiguration]()

    private var blurView:UIVisualEffectView?
	private var sectionHeaderFont = UIFont(name: ThemeHelper.defaultFontNameMedium, size: ThemeHelper.smallFontSize - 1)
    private var initialLoadComplete = false
	
	private lazy var allMusicCellConfiguration:CellConfiguration = {
        let title = "ALL MUSIC"
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
        tableView.sectionFooterHeight = 0
        tableView.backgroundColor = UIColor.clearColor()
        tableView.registerClass(AbstractTableViewCell.self, forCellReuseIdentifier: KyoozNavigationViewController.reuseIdentifier)
		
		func cellConfigurationForGrouping(libraryGrouping:LibraryGrouping) -> CellConfiguration {
			let title = libraryGrouping.name
			let action = {
				let vc = AudioEntityLibraryViewController()
				vc.sourceData = MediaQuerySourceData(filterQuery: libraryGrouping.baseQuery, libraryGrouping: libraryGrouping)
				vc.subGroups = [LibraryGrouping]()
				vc.title = title
				ContainerViewController.instance.pushViewController(vc)
			}
			return BasicCellConfiguration(name: title, action: action)
		}
		
		var musicGroupings:[CellConfiguration] = [allMusicCellConfiguration]
		musicGroupings.appendContentsOf(LibraryGrouping.otherMusicGroupings.map(cellConfigurationForGrouping))
		sectionConfigurations.append(SectionConfiguration(sectionName: "MUSIC", cellConfigurations: musicGroupings))
		
		let otherAudio = LibraryGrouping.otherGroupings.map(cellConfigurationForGrouping)
		sectionConfigurations.append(SectionConfiguration(sectionName: "OTHER AUDIO", cellConfigurations:  otherAudio))
		sectionConfigurations.append(SectionConfiguration(sectionName: "SETTINGS", cellConfigurations:  [settingsCellConfiguration]))
		
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
        
        let cancelButton = CrossButtonView()
        cancelButton.showsCircle = false
        cancelButton.scale = 0.35
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
		
		if !initialLoadComplete {
			KyoozUtils.doInMainQueueAsync() {
				self.initialLoadComplete = true
				KyoozUtils.doInMainQueueAsync(self.animateCells)
			}
		}
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
		return sectionConfigurations.count
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sectionConfigurations[section].count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(KyoozNavigationViewController.reuseIdentifier) ?? AbstractTableViewCell()
		cell.textLabel?.text = sectionConfigurations[indexPath.section][indexPath.row].name
		cell.textLabel?.font = ThemeHelper.defaultFont
        cell.textLabel?.textColor = ThemeHelper.defaultFontColor
        if !initialLoadComplete {
            cell.contentView.alpha = 0
        }
		cell.backgroundColor = UIColor.clearColor()
        
        if indexPath.row == 0 && indexPath.section == 0 {
            let homeView = HomeButtonView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            homeView.userInteractionEnabled = false
            cell.accessoryView = homeView
        }

		return cell
	}

	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        let cellConfiguration = sectionConfigurations[indexPath.section][indexPath.row]
		
        cellConfiguration.action()
        
        transitionOut()
	}
	
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

		let label = UILabel()
		label.text = "\(sectionConfigurations[section].sectionName)"
		label.textAlignment = .Center
        
		label.font = sectionHeaderFont
		label.textColor = ThemeHelper.defaultFontColor
        label.alpha = ThemeHelper.defaultButtonTextAlpha
        
        return label
	}
	
	//only implementing this method because of a bug with viewForHeaderInSection
	//which doesnt load the first section unless this method is implemented
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 30
	}
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionConfigurations[section].sectionName
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
