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
		$0.setTitle("", for: UIControlState())
		$0.setTitleColor(ThemeHelper.defaultFontColor, for: UIControlState())
		$0.setTitleColor(ThemeHelper.defaultVividColor, for: .highlighted)
		$0.titleLabel?.font = UIFont(name: ThemeHelper.defaultFontName, size: ThemeHelper.smallFontSize+1)
		$0.addTarget(self, action: #selector(self.showSubGroupings(_:)), for: .touchUpInside)
		
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
			libraryGroupingButton.isHidden = false
			setActiveGroup(group)
		}
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override func loadView() {
		view = libraryGroupingButton
	}
	
    @objc func showSubGroupings(_ sender: AnyObject) {
		
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
		let center = libraryGroupingButton.convert(CGPoint(x:libraryGroupingButton.bounds.midX, y: libraryGroupingButton.bounds.midY), to: UIScreen.main.fixedCoordinateSpace)
		b.with(originatingCenter: center)
		KyoozUtils.showMenuViewController(b.viewController)
	}
	
	private func setActiveGroup(_ group:LibraryGrouping) {
		libraryGroupingButton.setTitle("  \(group.name) ⇣", for: UIControlState())
	}

}
