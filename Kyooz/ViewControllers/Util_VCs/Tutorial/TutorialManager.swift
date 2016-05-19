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
    lazy var tutorialViewControllerFactory = TutorialViewControllerFactory()
	
    let tutorialDataMap:[Tutorial:TutorialDTO] = {
        var tutorials = [TutorialDTO]()
        tutorials.append(TutorialDTO(tutorial: .DragAndDrop,
            instructionText: "Press and hold a cell to drag and drop it on to the play queue",
            nextTutorial: .InsertOrCancel))
        
        tutorials.append(TutorialDTO(tutorial: .GestureActivatedSearch,
            instructionText: "Swipe to the right to search everywhere",
            nextTutorial: nil))
        
        tutorials.append(TutorialDTO(tutorial: .GestureToViewQueue,
            instructionText: "Swipe to the left to view the play queue",
            nextTutorial: nil))
        
        tutorials.append(TutorialDTO(tutorial: .InsertOrCancel,
            instructionText: "Let go to insert the tracks\nMove left to cancel",
            nextTutorial: nil))
        
        tutorials.append(TutorialDTO(tutorial: .DragToRearrange,
            instructionText: "Press and hold on a cell in the play queue to rearrange",
            nextTutorial: nil))
        
        var map = [Tutorial:TutorialDTO]()
        for dto in tutorials {
            map[dto.tutorial] = dto
        }
        return map
    }()
    
    weak var presentedTutorial:TutorialViewController?
    
    func dimissTutorials(tutorials:[Tutorial], action:TutorialAction) {
        for tutorial in tutorials {
            if dismissTutorial(tutorial, action: action){
                break
            }
        }
    }
    
    func dismissTutorial(tutorial:Tutorial, action:TutorialAction) -> Bool {
        guard let tvc = presentedTutorial where tvc.tutorialDTO.tutorial == tutorial else {
            return false
        }
        
        switch action {
        case .DismissFulfilled, .Fulfill:
            setFulfulled(tutorial, fulfilled: true)
            break
        case .DismissUnfulfilled:
            break
        }
        
        tvc.transitionOut(action)
        return true
    }
    
    func resetAllTutorials() {
        tutorialDataMap.forEach() {
            setFulfulled($0.0, fulfilled: false)
        }
    }
	
    private func setFulfulled(tutorial:Tutorial, fulfilled:Bool) {
		userDefaults.setBool(fulfilled, forKey: self.dynamicType.keyForTutorial(tutorial))
	}
    
    //use this function when the intention is to present one of many
    //unfulfilled tutorials in the same invocation
    func presentUnfulfilledTutorials(tutorials:[Tutorial]) {
        for tutorial in tutorials {
            if presentTutorialIfUnfulfilled(tutorial) {
                break
            }
        }
    }
	
	func presentTutorialIfUnfulfilled(tutorial:Tutorial) -> Bool {
        guard !tutorialIsFulfilled(tutorial) else {
            return false
        }
        
        if let tvc = presentedTutorial {
            if tvc.tutorialDTO.tutorial == tutorial {
                return true
            } else {
                //this dismisses the presenting tutorial when a new one is requested to be shown
                dismissTutorial(tvc.tutorialDTO.tutorial, action: .DismissUnfulfilled)
            }
        }
        
        guard let dto = tutorialDataMap[tutorial] else {
            fatalError("no tutorial defined for \(tutorial)")
        }
        
        let tvc:TutorialViewController = tutorialViewControllerFactory.viewControllerForTutorial(dto)
		ConstraintUtils.applyStandardConstraintsToView(subView: tvc.view, parentView: presentationController.view)
		presentationController.addChildViewController(tvc)
		tvc.didMoveToParentViewController(presentationController)
        presentedTutorial = tvc
        return true
	}
	
	private func tutorialIsFulfilled(tutorial:Tutorial) -> Bool {
		return userDefaults.boolForKey(self.dynamicType.keyForTutorial(tutorial))
	}
	
    static func keyForTutorial(tutorial:Tutorial) -> String {
		return "\(userDefaultKeyPrefix)\(tutorial)"
	}
    
    
	
}