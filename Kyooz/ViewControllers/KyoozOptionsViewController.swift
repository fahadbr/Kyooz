//
//  KyoozOptionsViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/9/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit



final class KyoozOptionsViewController: FadeOutViewController, UITableViewDataSource, UITableViewDelegate {

	private typealias This = KyoozOptionsViewController
	
    private static let cellHeight:CGFloat = 50
    private static let sectionHeight:CGFloat = 5
    
    private static let absoluteMax:CGFloat = UIScreen.mainScreen().bounds.width * 95
	
	private let maxWidth:CGFloat = min(375 * 0.70, This.absoluteMax)
	private let minWidth:CGFloat = min(UIScreen.mainScreen().bounds.width * 0.55 * ThemeHelper.contentSizeRatio, This.absoluteMax)
	private let maxHeight:CGFloat = UIScreen.mainScreen().bounds.height * 0.95
    
	private let tableView = UITableView()
    
    private lazy var dividerPath:UIBezierPath = {
        let path = UIBezierPath()
        let inset:CGFloat = 12
        let midLine = This.sectionHeight/2
        path.moveToPoint(CGPoint(x: inset, y: midLine))
        path.addLineToPoint(CGPoint(x: self.tableView.frame.width - inset, y: midLine))
        return path
    }()
    
    private var menuActions = [[KyoozMenuActionProtocol]]()

	let headerProvider:KyoozOptionsHeaderProvider
	let originatingCenter:CGPoint?
	
	init(headerProvider:KyoozOptionsHeaderProvider, originatingCenter:CGPoint? = nil) {
		self.headerProvider = headerProvider
		self.originatingCenter = originatingCenter
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fadeOutAnimation.duration = 0.2
        menuActions.append([CancelAction()])
		
		let tableHeaderView = headerProvider.headerView(withMaxSize: CGSize(width: maxWidth, height: maxHeight))
		let tableHeaderSize = tableHeaderView.frame.size ?? CGSize.zero
		let height = This.cellHeight
			* CGFloat(menuActions.reduce(0) { $0 + $1.count })
			+ tableHeaderSize.height
			+ This.sectionHeight
			* CGFloat(menuActions.count)
		
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
		
        //animate the menu from the originating center to the screens center
        let center = originatingCenter ?? view.center
        let transformAnimation = CABasicAnimation(keyPath: "transform")
        let scaleTransform = CATransform3DMakeScale(0.1, 0.1, 0)
        let translationTransform = CATransform3DMakeTranslation(abs(center.x) - view.center.x, abs(center.y) - view.center.y, 0)
        
        transformAnimation.fromValue = NSValue(CATransform3D: CATransform3DConcat(scaleTransform, translationTransform))
        transformAnimation.toValue = NSValue(CATransform3D: CATransform3DIdentity)
        transformAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        transformAnimation.duration = 0.2
        transformAnimation.fillMode = kCAFillModeBackwards
        
        tableContainerView.layer.addAnimation(transformAnimation, forKey: nil)
    }
	
	
    func addActions(menuActions:[KyoozMenuActionProtocol]) {
        self.menuActions.append(menuActions)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return menuActions.count
    }
	
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return menuActions[section].count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(KyoozMenuCell.reuseIdentifier) as? KyoozMenuCell else {
            return UITableViewCell()
        }
		let action = menuActions[indexPath.section][indexPath.row]
			
        cell.textLabel?.text = action.title
        cell.imageView?.image = action.image
        return cell
	}
	
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        ContainerViewController.instance.longPressGestureRecognizer?.enabled = true
		menuActions[indexPath.section][indexPath.row].action?()
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

private struct CancelAction : KyoozMenuActionProtocol {
    var title: String { return "CANCEL" }
    var image: UIImage? { return nil }
    var action: (() -> ())? { return nil }
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
