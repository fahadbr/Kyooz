//
//  TutorialManager.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/12/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class TutorialManager {
	
	static let instance = TutorialManager()
	
	private static let userDefaultKeyPrefix = "KyoozTutorialFulfilled."
	
	//MARK: - DEPENDENCIES
	lazy var userDefaults = NSUserDefaults.standardUserDefaults()
	lazy var presentationController:UIViewController = ContainerViewController.instance
	
	
//	var 
	
	func fulfullTutorial(tutorial:Tutorial) {
		userDefaults.setBool(true, forKey: keyForTutorial(tutorial))
	}
	
	func presentTutorialIfUnfulfilled(tutorial:Tutorial) {
		guard !tutorialIsFulfilled(tutorial) else {
			Logger.debug("tutorial has already been fulfilled")
			return
		}
		let tvc = TutorialViewController(text: "Tutorial Example", forTutorial: .DragAndDrop)
		ConstraintUtils.applyStandardConstraintsToView(subView: tvc.view, parentView: presentationController.view)
		presentationController.addChildViewController(tvc)
		tvc.didMoveToParentViewController(presentationController)
	}
	
	private func tutorialIsFulfilled(tutorial:Tutorial) -> Bool {
		return userDefaults.boolForKey(keyForTutorial(tutorial))
	}
	
	private func keyForTutorial(tutorial:Tutorial) -> String {
		return "\(self.dynamicType.userDefaultKeyPrefix)\(tutorial.rawValue)"
	}
	
}