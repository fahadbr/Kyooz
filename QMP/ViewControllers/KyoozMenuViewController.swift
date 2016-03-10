//
//  KyoozMenuViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/9/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class KyoozMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private static let cellHeight:CGFloat = 44
    
	private let tableView = UITableView()
    private var menuActions:[KyoozMenuAction] = [KyoozMenuAction]() {
        didSet {
            estimatedSize = CGSize(width: UIScreen.mainScreen().bounds.width * 0.55, height: self.dynamicType.cellHeight * CGFloat(menuActions.count))
            if menuTitle != nil {
                estimatedSize.height += 40
            }
        }
    }
    
    private var estimatedSize:CGSize = CGSize.zero
	
    var menuTitle:String? {
        didSet {
            let label = UILabel()
            label.frame = CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.width * 0.55, height: 40)
            label.textAlignment = .Center
            label.text = menuTitle
            label.font = ThemeHelper.defaultFont
            label.textColor = ThemeHelper.defaultVividColor
            tableView.tableHeaderView = label
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if estimatedSize.height < UIScreen.mainScreen().bounds.height * 0.9 {
            tableView.scrollEnabled = false
        }
        let tableContainerView = UIView()
        ViewUtils.applyConstraintsToView(withAnchors: [.CenterX, .CenterY], subView: tableContainerView, parentView: view)
        tableContainerView.heightAnchor.constraintEqualToConstant(estimatedSize.height).active = true
        tableContainerView.widthAnchor.constraintEqualToConstant(estimatedSize.width).active = true
        ViewUtils.applyStandardConstraintsToView(subView: tableView, parentView: tableContainerView)
		tableView.rowHeight = self.dynamicType.cellHeight
        tableView.delegate = self
        tableView.dataSource = self
		tableView.layer.cornerRadius = 15
		tableView.registerClass(KyoozMenuCell.self, forCellReuseIdentifier: KyoozMenuCell.reuseIdentifier)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 11)
        
        tableContainerView.layer.shadowOpacity = 0.8
        tableContainerView.layer.shadowOffset = CGSize(width: 0, height: 0)
        tableContainerView.layer.shadowRadius = 6.0
        tableContainerView.layer.shadowColor = ThemeHelper.defaultVividColor.CGColor
        
        view.backgroundColor = UIColor(white: 0, alpha: 0.40)
    }
    
    func addAction(menuAction:KyoozMenuAction) {
        menuActions.append(menuAction)
    }
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return menuActions.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(KyoozMenuCell.reuseIdentifier) as? KyoozMenuCell else {
            return UITableViewCell()
        }
        let action = menuActions[indexPath.row]
        
        cell.textLabel?.text = action.title
        cell.imageView?.image = action.image
        return cell
	}
	
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        menuActions[indexPath.row].action?()
        guard let superView = view.superview else { return }
        UIView.transitionWithView(superView, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: { () -> Void in
                self.view.removeFromSuperview()
                self.removeFromParentViewController()
            }, completion: {_ in
                ContainerViewController.instance.longPressGestureRecognizer?.enabled = true
        })

    }
    

}

struct KyoozMenuAction {
    
    let title:String
    let image:UIImage?
    let action:(()->())?
}

private final class KyoozMenuCell : AbstractTableViewCell {
	
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
        textLabel?.textColor = ThemeHelper.defaultFontColor
        textLabel?.textAlignment = NSTextAlignment.Center
	}
	
}
