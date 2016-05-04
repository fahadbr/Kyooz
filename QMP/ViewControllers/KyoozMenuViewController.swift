//
//  KyoozMenuViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/9/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

private let largerMenuFont = ThemeHelper.defaultFont?.fontWithSize(16)

final class KyoozMenuViewController: FadeOutViewController, UITableViewDataSource, UITableViewDelegate {

    private static let cellHeight:CGFloat = 50
    private static let sectionHeight:CGFloat = 5
	
	private let maxWidth:CGFloat = UIScreen.mainScreen().bounds.width * 0.70
	private let minWidth:CGFloat = UIScreen.mainScreen().bounds.width * 0.55
	private let maxHeight:CGFloat = UIScreen.mainScreen().bounds.height * 0.9
    
	private let tableView = UITableView()
    
    private lazy var dividerPath:UIBezierPath = {
        let path = UIBezierPath()
        let inset:CGFloat = 12
        let containerWidth = self.tableView.frame.width
        let midLine = self.dynamicType.sectionHeight/2
        path.moveToPoint(CGPoint(x: inset, y: midLine))
        path.addLineToPoint(CGPoint(x: containerWidth - inset, y: midLine))
        return path
    }()
    
    private var menuActions = [[KyoozMenuActionProtocol]]()
	private var estimatedLabelContainerSize:CGSize {
		let titleSize = titleLabel?.frame.size ?? CGSize.zero
		let detailsSize = detailsLabel?.frame.size ?? CGSize.zero
		
		let assumedLabelHeight = titleSize.height + detailsSize.height
		let assumedLabelWidth = max(titleSize.width, detailsSize.width)
		return CGSize(width: max(min(maxWidth, assumedLabelWidth), minWidth), height: assumedLabelHeight)
	}
	
	private var labelContainerView:UIView!
	private var titleLabel:UILabel!
	private var detailsLabel:UILabel!
	
	var originatingCenter:CGPoint?
	var menuTitle:String? {
        didSet {
			configureLabelSizes()
        }
    }
	
	var menuDetails:String? {
		didSet {
			configureLabelSizes()
		}
	}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fadeOutAnimation.duration = 0.2
        menuActions.append([CancelAction()])
        initializeLabelContainerView()
		
		let labelContainerSize = labelContainerView?.frame.size ?? CGSize.zero
		let height = self.dynamicType.cellHeight * CGFloat(menuActions.flatten().count) + labelContainerSize.height + self.dynamicType.sectionHeight * CGFloat(menuActions.count)
		let width = labelContainerSize.width
		let estimatedSize = CGSize(width: width, height: height)

        
		if estimatedSize.height < maxHeight {
            tableView.scrollEnabled = false
        }
		
        let tableContainerView = UIView()
        ConstraintUtils.applyConstraintsToView(withAnchors: [.CenterX, .CenterY], subView: tableContainerView, parentView: view)
        tableContainerView.heightAnchor.constraintEqualToConstant(estimatedSize.height).active = true
        tableContainerView.widthAnchor.constraintEqualToConstant(estimatedSize.width).active = true

        
        ConstraintUtils.applyStandardConstraintsToView(subView: tableView, parentView: tableContainerView)
        tableView.scrollsToTop = false
		tableView.rowHeight = self.dynamicType.cellHeight
        tableView.sectionHeaderHeight = self.dynamicType.sectionHeight
        tableView.delegate = self
        tableView.dataSource = self
		tableView.layer.cornerRadius = 10
		tableView.registerClass(KyoozMenuCell.self, forCellReuseIdentifier: KyoozMenuCell.reuseIdentifier)
        tableView.separatorStyle = .None
        tableView.tableHeaderView = labelContainerView
        
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
	
	private func initializeLabelContainerView() {
		func configureCommonLabelAttributes(label:UILabel, text:String?, font:UIFont!) {
			label.textAlignment = .Center
			label.numberOfLines = 0
			label.lineBreakMode = .ByWordWrapping
			label.textColor = ThemeHelper.defaultVividColor
			label.text = text
			label.font = font ?? ThemeHelper.defaultFont
		}
		
		titleLabel = UILabel()
		configureCommonLabelAttributes(titleLabel, text: menuTitle, font:largerMenuFont)
		
		detailsLabel = UILabel()
		configureCommonLabelAttributes(detailsLabel, text: menuDetails, font:ThemeHelper.smallFontForStyle(.Normal))
		
		configureLabelSizes()
		
		let stackView = UIStackView(arrangedSubviews: [titleLabel, detailsLabel])
		stackView.axis = UILayoutConstraintAxis.Vertical
		let labelSize = estimatedLabelContainerSize
        stackView.frame.size = labelSize

		let offset:CGFloat = 16
		let containerSize = CGSize(width: labelSize.width + offset, height: labelSize.height + offset)
		labelContainerView = UIView()
        labelContainerView.frame.size = containerSize
		
        stackView.center = labelContainerView.center
        labelContainerView.addSubview(stackView)

	}
	
	private func configureLabelSizes() {
		func configureBoundsForLabel(label:UILabel!) {
			guard label != nil else { return }
			
			let rect = label.textRectForBounds(CGRect(x: 0, y: 0, width: maxWidth, height: UIScreen.mainScreen().bounds.height), limitedToNumberOfLines: 0)
			label.frame.size = CGSize(width: max(min(rect.size.width, maxWidth), minWidth), height: rect.size.height)
		}
		configureBoundsForLabel(titleLabel)
		configureBoundsForLabel(detailsLabel)
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
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: self.dynamicType.sectionHeight))

        let dividerPathLayer = CAShapeLayer()
        dividerPathLayer.path = dividerPath.CGPath
        dividerPathLayer.strokeColor = UIColor.darkGrayColor().CGColor
        dividerPathLayer.lineWidth = 0.5
        
        dividerPathLayer.frame = view.bounds
        view.layer.addSublayer(dividerPathLayer)
        return view
    }
    

}

protocol KyoozMenuActionProtocol {
    var title:String { get }
    var image:UIImage? { get }
    var action:(()->())? { get }
}

struct KyoozMenuAction : KyoozMenuActionProtocol {
    
    let title:String
    let image:UIImage?
    let action:(()->())?
}

private struct CancelAction : KyoozMenuActionProtocol {
    var title: String { return "CANCEL" }
    var image: UIImage? { return nil }
    var action: (() -> ())? { return nil }
}

private final class KyoozMenuCell : AbstractTableViewCell {
	
	static let reuseIdentifier = "kyoozMenuCell"
    static let font = UIFont(name: ThemeHelper.defaultFontName, size: ThemeHelper.defaultFontSize)
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}
	
	func initialize() {
        backgroundColor = UIColor.clearColor()
		textLabel?.font = self.dynamicType.font
        textLabel?.textColor = ThemeHelper.defaultFontColor
        textLabel?.textAlignment = NSTextAlignment.Center
	}
	
}
