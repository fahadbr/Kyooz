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
	
    lazy var tutorialDataMap:[Tutorial:TutorialDTO] = {
        var tutorials = [TutorialDTO]()
        tutorials.append(TutorialDTO(tutorial: .DragAndDrop,
            instructionText: "Press and hold a cell to place it on to the play queue",
            nextTutorial: .InsertOrCancel))
        
        tutorials.append(TutorialDTO(tutorial: .GestureActivatedSearch,
            instructionText: "Swipe to the right to search everywhere",
            nextTutorial: nil))
        
        tutorials.append(TutorialDTO(tutorial: .GestureToViewQueue,
            instructionText: "Swipe to the left to view the play queue",
            nextTutorial: nil))
        
        tutorials.append(TutorialDTO(tutorial: .InsertOrCancel,
            instructionText: "Let go to insert the tracks. Move it left to cancel",
            nextTutorial: nil))
        
        tutorials.append(TutorialDTO(tutorial: .DragToRearrange,
            instructionText: "Press and hold to rearrange cells",
            nextTutorial: nil))
        
        var map = [Tutorial:TutorialDTO]()
        for dto in tutorials {
            map[dto.tutorial] = dto
        }
        return map
    }()
    
    private weak var presentedTutorial:TutorialViewController?
    
    func dismissTutorial(tutorial:Tutorial, action:TutorialAction) {
        guard let tvc = presentedTutorial where tvc.tutorialDTO.tutorial == tutorial else {
            Logger.debug("cannot dismiss tutorial \(tutorial.rawValue) when its not being presented")
            return
        }
        
        switch action {
        case .DismissFulfilled, .Fulfill:
            setFulfulled(tutorial, fulfilled: true)
            break
        case .DismissUnfulfilled:
            break
        }
        tvc.transitionOut(action)
        
    }
    
    func resetAllTutorials() {
        tutorialDataMap.forEach() {
            setFulfulled($0.0, fulfilled: false)
        }
    }
	
    private func setFulfulled(tutorial:Tutorial, fulfilled:Bool) {
		userDefaults.setBool(fulfilled, forKey: keyForTutorial(tutorial))
	}
	
	func presentTutorialIfUnfulfilled(tutorial:Tutorial) {
        guard presentedTutorial == nil else {
            Logger.debug("already presenting a tutorial")
            return
        }
		guard !tutorialIsFulfilled(tutorial) else {
			Logger.debug("tutorial has already been fulfilled")
			return
		}
        guard let dto = tutorialDataMap[tutorial] else {
            fatalError("no tutorial defined for \(tutorial.rawValue)")
        }
        let tvc = TutorialViewController(tutorialDTO:dto)
		ConstraintUtils.applyStandardConstraintsToView(subView: tvc.view, parentView: presentationController.view)
		presentationController.addChildViewController(tvc)
		tvc.didMoveToParentViewController(presentationController)
        presentedTutorial = tvc
	}
	
	private func tutorialIsFulfilled(tutorial:Tutorial) -> Bool {
		return userDefaults.boolForKey(keyForTutorial(tutorial))
	}
	
	private func keyForTutorial(tutorial:Tutorial) -> String {
		return "\(self.dynamicType.userDefaultKeyPrefix)\(tutorial.rawValue)"
	}
	
}