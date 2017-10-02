//
//  LibraryHomeViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/19/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

fileprivate protocol CellConfiguration {
    var name:String { get }
    var action:()->() { get }
}

fileprivate struct BasicCellConfiguration : CellConfiguration {
    let name:String
    let action:()->()
}

fileprivate struct SectionConfiguration {
	let sectionName:String
	let cellConfigurations:[CellConfiguration]
	var count:Int { return cellConfigurations.count }
	subscript(i:Int) -> CellConfiguration {
		return cellConfigurations[i]
	}
}


final class KyoozNavigationViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
	
    fileprivate static let reuseIdentifier = "kyoozNavigationViewControllerCell"
    
    fileprivate let fadeOutAnimation = KyoozUtils.fadeOutAnimationWithDuration(0.4)
    
	fileprivate let tableView = UITableView(frame: CGRect.zero, style: .grouped)
    
    fileprivate var sectionConfigurations = [SectionConfiguration]()

    fileprivate var blurView:UIVisualEffectView?
	fileprivate var sectionHeaderFont = UIFont(name: ThemeHelper.defaultFontNameMedium, size: ThemeHelper.smallFontSize - 1)
    fileprivate var initialLoadComplete = false
	
	fileprivate lazy var allMusicCellConfiguration:CellConfiguration = {
        let title = "ALL MUSIC"
		let action = { () -> () in
			RootViewController.instance.libraryNavigationController.popToRootViewController(animated: true)
		}
        return BasicCellConfiguration(name:title, action: action)
	}()
	
	fileprivate lazy var settingsCellConfiguration:CellConfiguration = {
		let action = {
			ContainerViewController.instance.present(UIStoryboard.settingsViewController(), animated: true, completion: nil)
		}
		return BasicCellConfiguration(name:"SETTINGS", action: action)
	}()
	
	override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        fadeOutAnimation.delegate = self
		let headerHeight:CGFloat = ThemeHelper.plainHeaderHight
        let headerView = PlainHeaderView()
        headerView.effect = nil
        ConstraintUtils.applyConstraintsToView(withAnchors: [.top, .left, .right], subView: headerView, parentView: view)
        headerView.heightAnchor.constraint(equalToConstant: headerHeight).isActive = true

		ConstraintUtils.applyConstraintsToView(withAnchors: [.left, .right, .bottom], subView: tableView, parentView: view)
        tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        tableView.separatorStyle = .singleLine
		tableView.rowHeight = 50
        tableView.sectionFooterHeight = 0
        tableView.backgroundColor = UIColor.clear
        
        tableView.register(AbstractTableViewCell.self, forCellReuseIdentifier: KyoozNavigationViewController.reuseIdentifier)
		
		func cellConfigurationForGrouping(_ libraryGrouping:LibraryGrouping) -> CellConfiguration {
			let title = libraryGrouping.name
			let action = {
				let vc = AudioEntityLibraryViewController()
				vc.sourceData = MediaQuerySourceData(filterQuery: libraryGrouping.baseQuery, libraryGrouping: libraryGrouping)
				vc.title = title
				ContainerViewController.instance.pushViewController(vc)
			}
			return BasicCellConfiguration(name: title, action: action)
		}
		
		var musicGroupings:[CellConfiguration] = [allMusicCellConfiguration]
        musicGroupings.append(contentsOf: LibraryGrouping.otherMusicGroupings.map(cellConfigurationForGrouping))
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
        titleLabel.textAlignment = .center
        ConstraintUtils.applyConstraintsToView(withAnchors: [.left, .right, .bottom], subView: titleLabel, parentView: headerView.contentView)
        titleLabel.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        
        let cancelButton = CrossButtonView()
        ConstraintUtils.applyConstraintsToView(withAnchors: [.right, .bottom], subView: cancelButton, parentView: headerView.contentView)
        cancelButton.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        cancelButton.widthAnchor.constraint(equalTo: cancelButton.heightAnchor).isActive = true
        cancelButton.addTarget(self, action: #selector(self.transitionOut), for: .touchUpInside)
	}
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateCells()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let blurView = UIVisualEffectView()
        self.blurView = blurView
        ConstraintUtils.applyStandardConstraintsToView(subView: blurView, parentView: view)
        view.sendSubview(toBack: blurView)
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseIn, animations: {
            blurView.effect = UIBlurEffect(style: .dark)
        }, completion: nil)
		
		if !initialLoadComplete {
			KyoozUtils.doInMainQueueAsync() {
				self.initialLoadComplete = true
				KyoozUtils.doInMainQueueAsync(self.animateCells)
			}
		}
    }
    
    fileprivate func animateCells() {
        var delay:Double = 0
        for cell in tableView.visibleCells {
            cell.alpha = 0
            cell.contentView.alpha = 1
            UIView.animate(withDuration: 0.35, delay: delay, options: .curveEaseOut, animations: {
                cell.alpha = 1
                }, completion: nil)
            delay += 0.05
        }
    }

    
	func numberOfSections(in tableView: UITableView) -> Int {
		return sectionConfigurations.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sectionConfigurations[section].count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: KyoozNavigationViewController.reuseIdentifier) ?? AbstractTableViewCell()
		cell.textLabel?.text = sectionConfigurations[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row].name
		cell.textLabel?.font = ThemeHelper.defaultFont
        cell.textLabel?.textColor = ThemeHelper.defaultFontColor
        if !initialLoadComplete {
            cell.contentView.alpha = 0
        }
		cell.backgroundColor = UIColor.clear
        
        if (indexPath as NSIndexPath).row == 0 && (indexPath as NSIndexPath).section == 0 {
            let homeView = HomeButtonView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            homeView.isUserInteractionEnabled = false
            cell.accessoryView = homeView
        }

		return cell
	}

	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
        
        let cellConfiguration = sectionConfigurations[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
		
        cellConfiguration.action()
        
        transitionOut()
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = " "
        cell.backgroundColor = UIColor.clear
        if let label = cell.detailTextLabel {
            label.text = "\(sectionConfigurations[section].sectionName)"
            label.textAlignment = .center
            label.font = sectionHeaderFont
            label.textColor = ThemeHelper.defaultFontColor
            label.alpha = ThemeHelper.defaultButtonTextAlpha
        }
        return cell
	}
	
	//only implementing this method because of a bug with viewForHeaderInSection
	//which doesnt load the first section unless this method is implemented
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 45
	}
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionConfigurations[section].sectionName
    }
	
    @objc func transitionOut() {
        ContainerViewController.instance.longPressGestureRecognizer.isEnabled = true
        view.layer.add(fadeOutAnimation, forKey: nil)
    }
}

extension KyoozNavigationViewController: CAAnimationDelegate {

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        blurView?.removeFromSuperview()
        blurView = nil
        view.layer.removeAllAnimations()
        view.removeFromSuperview()
        removeFromParentViewController()
    }
}
