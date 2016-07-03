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
    func animation(forView view: UIView) -> CAAnimation
    
}

class KyoozOptionsViewController: FadeOutViewController, UITableViewDataSource, UITableViewDelegate {

	private typealias This = KyoozOptionsViewController
	
    private static let cellHeight:CGFloat = 50
    private static let sectionHeight:CGFloat = 5
    
	private let tableView = UITableView()
    
    private lazy var dividerPath:UIBezierPath = {
        let path = UIBezierPath()
        let inset:CGFloat = 12
        let midLine = This.sectionHeight/2
        path.moveToPoint(CGPoint(x: inset, y: midLine))
        path.addLineToPoint(CGPoint(x: self.tableView.frame.width - inset, y: midLine))
        return path
    }()
    
    private var optionsProviders: [KyoozOptionsProvider]
    private let delegate: KyoozOptionsViewControllerDelegate
	
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
        fadeOutAnimation.duration = 0.2
        optionsProviders.append(BasicKyoozOptionsProvider(options:KyoozMenuAction(title:"CANCEL")))
        
        let sizeConstraint = delegate.sizeConstraint
        let maxWidth = sizeConstraint.maxWidth
        let maxHeight = sizeConstraint.maxHeight
		
		let tableHeaderView = delegate.headerView
		let tableHeaderSize = tableHeaderView.frame.size ?? CGSize.zero
		let height = This.cellHeight
			* CGFloat(optionsProviders.reduce(0) { $0 + $1.options.count })
			+ tableHeaderSize.height
			+ This.sectionHeight
			* CGFloat(optionsProviders.count)
		
		let width = tableHeaderSize.width
		let estimatedSize = CGSize(width: width, height: height)

		if estimatedSize.height < maxHeight {
            tableView.scrollEnabled = false
        }
		
        let tableContainerView = UIView()
		view.add(subView: tableContainerView, with: [.CenterX, .CenterY])
		tableContainerView.constrain(height: min(estimatedSize.height, maxHeight),
		                             width: min(estimatedSize.width, maxWidth))

		
		tableContainerView.add(subView: tableView, with: Anchor.standardAnchors)
        tableView.scrollsToTop = false
		tableView.rowHeight = This.cellHeight
        tableView.sectionHeaderHeight = This.sectionHeight
        tableView.delegate = self
        tableView.dataSource = self
		tableView.layer.cornerRadius = 10
		tableView.registerClass(KyoozMenuCell.self, forCellReuseIdentifier: KyoozMenuCell.reuseIdentifier)
        tableView.separatorStyle = .None
        tableView.tableHeaderView = tableHeaderView
        
        tableContainerView.layer.shadowOpacity = 0.8
        tableContainerView.layer.shadowOffset = CGSize(width: 0, height: 0)
        tableContainerView.layer.shadowRadius = 4.0
        tableContainerView.layer.shadowColor = UIColor.whiteColor().CGColor
        
        view.backgroundColor = UIColor(white: 0, alpha: 0.40)
        
        tableContainerView.layer.addAnimation(delegate.animation(forView: view), forKey: nil)
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
        return cell
	}
	
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        ContainerViewController.instance.longPressGestureRecognizer?.enabled = true
		optionsProviders[indexPath.section].options[indexPath.row].action?()
        transitionOut()
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: This.sectionHeight))

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
    static let font = UIFont(name: ThemeHelper.defaultFontName, size: ThemeHelper.defaultFontSize)
	
	override func initialize() {
		super.initialize()
        backgroundColor = UIColor.clearColor()
		textLabel?.font = KyoozMenuCell.font
        textLabel?.textColor = ThemeHelper.defaultFontColor
        textLabel?.textAlignment = NSTextAlignment.Center
	}
	
}
