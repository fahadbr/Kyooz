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
		return $0
	}(UIButton())
	
	var subGroups:[LibraryGrouping]
	weak var audioEntityLibraryViewController:AudioEntityLibraryViewController?
    
	init(subGroups:[LibraryGrouping], aelvc:AudioEntityLibraryViewController) {
        self.subGroups = subGroups
		self.audioEntityLibraryViewController = aelvc
        super.init(nibName: nil, bundle: nil)
		
		let group = aelvc.sourceData.libraryGrouping
		if !subGroups.isEmpty && subGroups.contains(group) {
			libraryGroupingButton.hidden = false
			setActiveGroup(group)
		}
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override func loadView() {
		view = libraryGroupingButton
	}
	
	func showSubGroupings(sender: AnyObject) {
		
		let b = MenuBuilder().with(title: "Change Grouping Type")
    
		var actions = [KyoozOption]()
		for group in subGroups {
			actions.append(KyoozMenuAction(title: group.name) {
				self.setActiveGroup(group)
				if self.audioEntityLibraryViewController?.groupingTypeDidChange(group) == nil {
					fatalError("failed to change grouping type")
				}
			})
		}
		b.with(options: actions)
		let center = libraryGroupingButton.convertPoint(CGPoint(x:libraryGroupingButton.bounds.midX, y: libraryGroupingButton.bounds.midY), toCoordinateSpace: UIScreen.mainScreen().fixedCoordinateSpace)
		b.with(originatingCenter: center)
		KyoozUtils.showMenuViewController(b.viewController)
	}
	
	private func setActiveGroup(group:LibraryGrouping) {
		libraryGroupingButton.setTitle("  \(group.name) ⇣", forState: .Normal)
	}

}
