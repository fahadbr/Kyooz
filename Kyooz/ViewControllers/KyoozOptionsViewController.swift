//
//  KyoozOptionsViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/9/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

protocol KyoozOptionsViewControllerDelegate {
    
    var sizeConstraint: SizeConstraint { get }
    var headerView: UIView { get }
    var sectionDividerPosition: CGFloat { get }
    var sectionHeight: CGFloat { get }
    
    func animation(forView view: UIView) -> CAAnimation
    
    func headerView(forSection section: Int) -> UIView
    
}

class KyoozOptionsViewController: UIViewController, FadeOutViewController, UITableViewDataSource, UITableViewDelegate {

	private typealias This = KyoozOptionsViewController
	
    static let cellHeight:CGFloat = UIScreen.heightClass == .iPhone4 ? 45 : 50
    
	private let tableView = UITableView()
    
    private lazy var dividerPath:UIBezierPath = {
        let path = UIBezierPath()
        let inset:CGFloat = 12
        let midLine = self.delegate.sectionHeight * self.delegate.sectionDividerPosition
        path.moveToPoint(CGPoint(x: inset, y: midLine))
        path.addLineToPoint(CGPoint(x: self.tableView.frame.width - inset, y: midLine))
        return path
    }()
    
    private var optionsProviders: [KyoozOptionsProvider]
    private let delegate: KyoozOptionsViewControllerDelegate
    
    var animationDuration: Double {
        return 0.2
    }
	
    init(optionsProviders:[KyoozOptionsProvider],
         delegate:KyoozOptionsViewControllerDelegate) {
        
        self.optionsProviders = optionsProviders
        self.delegate = delegate
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let sizeConstraint = delegate.sizeConstraint
        let maxHeight = sizeConstraint.maxHeight
		
		let tableHeaderView = delegate.headerView
		let tableHeaderSize = tableHeaderView.frame.size ?? CGSize.zero
		let height = This.cellHeight
			* CGFloat(optionsProviders.reduce(0) { $0 + $1.options.count })
			+ tableHeaderSize.height
			+ delegate.sectionHeight
			* CGFloat(optionsProviders.count)
		
		let width = tableHeaderSize.width
		let estimatedSize = CGSize(width: width, height: height)
		
        let tableContainerView = UIView()
		view.add(subView: tableContainerView, with: [.CenterX, .CenterY])
		tableContainerView.constrain(height: min(estimatedSize.height, maxHeight),
		                             width: estimatedSize.width)

		
		tableContainerView.add(subView: tableView, with: Anchor.standardAnchors)
        tableView.scrollsToTop = false
		tableView.rowHeight = This.cellHeight
        tableView.sectionHeaderHeight = delegate.sectionHeight
        tableView.delegate = self
        tableView.dataSource = self
		tableView.layer.cornerRadius = 10
		tableView.registerClass(KyoozMenuCell.self, forCellReuseIdentifier: KyoozMenuCell.reuseIdentifier)
        tableView.separatorStyle = .None
        tableView.tableHeaderView = tableHeaderView
        tableView.indicatorStyle = .White
        tableView.scrollEnabled = estimatedSize.height > maxHeight
        
        tableContainerView.layer.shadowOpacity = 0.8
        tableContainerView.layer.shadowOffset = CGSize(width: 0, height: 0)
        tableContainerView.layer.shadowRadius = 4.0
        tableContainerView.layer.shadowColor = UIColor.whiteColor().CGColor
        
        view.backgroundColor = UIColor(white: 0, alpha: 0)
        UIView.animateWithDuration(0.2) {
            self.view.backgroundColor = UIColor(white: 0, alpha: 0.4)
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock() { [tableView = self.tableView] in
            if tableView.scrollEnabled {
                tableView.flashScrollIndicators()
            }
        }
        tableContainerView.layer.addAnimation(delegate.animation(forView: view), forKey: nil)
        CATransaction.commit()
    }
	
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return optionsProviders.count
    }
	
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return optionsProviders[section].options.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(KyoozMenuCell.reuseIdentifier) as? KyoozMenuCell else {
            return UITableViewCell()
        }
		let action = optionsProviders[indexPath.section].options[indexPath.row]
        
        cell.textLabel?.text = action.title
        
        if action.highlighted {
            let highlightLayer = CALayer()
            highlightLayer.backgroundColor = ThemeHelper.defaultVividColor.CGColor
            highlightLayer.cornerRadius = 5
            highlightLayer.frame = CGRect(x: 10, y: 5, width: delegate.sizeConstraint.maxWidth - 20, height: This.cellHeight - 10)
            cell.layer.insertSublayer(highlightLayer, below: cell.contentView.layer)
            cell.textLabel?.font = ThemeHelper.defaultFont(forStyle: .Bold)
        }
        return cell
	}
	
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        ContainerViewController.instance.longPressGestureRecognizer?.enabled = true
		optionsProviders[indexPath.section].options[indexPath.row].action?()
        transitionOut()
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = delegate.headerView(forSection: section)

        let dividerPathLayer = CAShapeLayer()
        dividerPathLayer.path = dividerPath.CGPath
        dividerPathLayer.strokeColor = UIColor.darkGrayColor().CGColor
        dividerPathLayer.lineWidth = 0.5
        
        dividerPathLayer.frame = view.bounds
        view.layer.addSublayer(dividerPathLayer)
        
        return view
    }
    

}

private final class KyoozMenuCell : AbstractTableViewCell {
	
	static let reuseIdentifier = "\(KyoozMenuCell.self)"
    static let font = ThemeHelper.defaultFont(forStyle: .Normal)
    
	override func initialize() {
		super.initialize()
        backgroundColor = UIColor.clearColor()
		textLabel?.font = KyoozMenuCell.font
        textLabel?.textColor = ThemeHelper.defaultFontColor
        textLabel?.textAlignment = NSTextAlignment.Center
	}
	
}
