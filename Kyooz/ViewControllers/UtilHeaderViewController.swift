//
//  UtilHeaderViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/16/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class UtilHeaderViewController: HeaderViewController {
    
    @IBOutlet var libraryGroupingButton: UIButton!
    
    var subGroups:[LibraryGrouping]? {
        didSet {
            if let group = subGroups?.first {
                libraryGroupingButton.hidden = false
                setActiveGroup(group)
            }
        }
    }
	
	private var path:UIBezierPath!
	private var accentLayer:CAShapeLayer = CAShapeLayer()
	
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clearColor()
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        ConstraintUtils.applyStandardConstraintsToView(subView: blurView, parentView: view)
        view.sendSubviewToBack(blurView)
		
		accentLayer.strokeColor = ThemeHelper.defaultVividColor.CGColor
		accentLayer.lineWidth = 0.75
		view.layer.addSublayer(accentLayer)
		
		libraryGroupingButton.alpha = ThemeHelper.defaultButtonTextAlpha
        libraryGroupingButton.hidden = subGroups == nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
		path = UIBezierPath()
		path.moveToPoint(CGPoint(x: view.bounds.origin.x, y: view.bounds.height))
		path.addLineToPoint(CGPoint(x: view.bounds.width, y: view.bounds.height))
		accentLayer.path = path.CGPath
    }
	
    override func didMoveToParentViewController(parent: UIViewController?) {
        super.didMoveToParentViewController(parent)
        guard let vc = parent as? AudioEntityLibraryViewController else { return }
        if vc.sourceData is GroupMutableAudioEntitySourceData {
            subGroups = vc.subGroups
        }
        setActiveGroup(vc.sourceData.libraryGrouping)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showSubGroupings(sender: AnyObject) {
        guard let groups = subGroups else { return }
        
		let kmvc = KyoozMenuViewController()
		kmvc.menuTitle = "Change Grouping Type"
        var actions = [KyoozMenuActionProtocol]()
        for group in groups {
			actions.append(KyoozMenuAction(title: group.name, image: nil, action: {
                self.setActiveGroup(group)
                (self.parentViewController as? AudioEntityLibraryViewController)?.groupingTypeDidChange(group)
            }))
        }
        kmvc.addActions(actions)
        let center = libraryGroupingButton.convertPoint(CGPoint(x:libraryGroupingButton.bounds.midX, y: libraryGroupingButton.bounds.midY), toCoordinateSpace: UIScreen.mainScreen().fixedCoordinateSpace)
		kmvc.originatingCenter = center
		KyoozUtils.showMenuViewController(kmvc)
    }
    
    private func setActiveGroup(group:LibraryGrouping) {
        libraryGroupingButton.setTitle("  \(group.name) ⇣", forState: .Normal)
    }
}
