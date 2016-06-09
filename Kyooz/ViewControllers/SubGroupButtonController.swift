//
//  SubGroupButtonController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/8/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class SubGroupButtonController: UIViewController {
	
	lazy var libraryGroupingButton: UIButton = {
		$0.setTitle("", forState: .Normal)
		$0.setTitleColor(ThemeHelper.defaultFontColor, forState: .Normal)
		$0.setTitleColor(ThemeHelper.defaultVividColor, forState: .Highlighted)
		$0.titleLabel?.font = UIFont(name: ThemeHelper.defaultFontName, size: ThemeHelper.smallFontSize+1)
		$0.addTarget(self, action: #selector(self.showSubGroupings(_:)), forControlEvents: .TouchUpInside)
		
		$0.alpha = ThemeHelper.defaultButtonTextAlpha
		$0.hidden = self.subGroups == nil
		return $0
	}(UIButton())
	
	var subGroups:[LibraryGrouping]? {
		didSet {
			if let group = subGroups?.first {
				libraryGroupingButton.hidden = false
				setActiveGroup(group)
			}
		}
	}
    
    init(subGroups:[LibraryGrouping]?) {
        self.subGroups = subGroups
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override func loadView() {
		view = libraryGroupingButton
	}
	
	func showSubGroupings(sender: AnyObject) {
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
