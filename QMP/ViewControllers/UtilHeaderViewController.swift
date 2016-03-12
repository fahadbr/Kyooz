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
    private let gradiantLayer:CAGradientLayer = {
        let gradiant = CAGradientLayer()
        gradiant.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradiant.endPoint = CGPoint(x: 0.5, y: 0)
        gradiant.colors = [ThemeHelper.darkAccentColor.CGColor, ThemeHelper.defaultTableCellColor.CGColor]
        return gradiant
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.layer.shadowOpacity = 0.8
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
		
//		view.backgroundColor = ThemeHelper.darkAccentColor
        view.layer.insertSublayer(gradiantLayer, atIndex: 0)
		
		libraryGroupingButton.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
        libraryGroupingButton.hidden = subGroups == nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradiantLayer.frame = view.bounds
    }
	
    override func didMoveToParentViewController(parent: UIViewController?) {
        super.didMoveToParentViewController(parent)
        guard let vc = parent as? AudioEntityLibraryViewController else { return }
        if vc.sourceData is GroupMutableAudioEntitySourceData {
            subGroups = vc.subGroups
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showSubGroupings(sender: AnyObject) {
        guard let groups = subGroups else { return }
        
		let kmvc = KyoozMenuViewController()
		kmvc.menuTitle = "Change Grouping Type"
        for group in groups {
			kmvc.addAction(KyoozMenuAction(title: group.name, image: nil, action: {
                self.setActiveGroup(group)
                (self.parentViewController as? AudioEntityLibraryViewController)?.groupingTypeDidChange(group)
            }))
        }
		kmvc.addAction(KyoozMenuAction(title: "Cancel", image: nil, action: nil))
		KyoozUtils.showMenuViewController(kmvc)
    }
    
    private func setActiveGroup(group:LibraryGrouping) {
        libraryGroupingButton.setTitle("  \(group.name) ⇣", forState: .Normal)
    }
}
