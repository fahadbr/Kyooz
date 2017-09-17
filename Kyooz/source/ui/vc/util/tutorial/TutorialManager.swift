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
	lazy var userDefaults = UserDefaults.standard
	lazy var presentationController:UIViewController = ContainerViewController.instance
    lazy var tutorialViewControllerFactory = TutorialViewControllerFactory()
	
    let tutorialDataMap:[Tutorial:TutorialDTO] = {
        var tutorials = [TutorialDTO]()
        tutorials.append(TutorialDTO(tutorial: .dragAndDrop,
            instructionText: "Press and hold a cell to drag and drop it on to the play queue",
            nextTutorial: .insertOrCancel))
        
        tutorials.append(TutorialDTO(tutorial: .gestureActivatedSearch,
            instructionText: "Swipe to the right to search everywhere",
            nextTutorial: nil))
        
        tutorials.append(TutorialDTO(tutorial: .gestureToViewQueue,
            instructionText: "Swipe to the left to view the play queue",
            nextTutorial: nil))
        
        tutorials.append(TutorialDTO(tutorial: .insertOrCancel,
            instructionText: "Let go to insert the tracks\nMove left to cancel",
            nextTutorial: nil))
        
        tutorials.append(TutorialDTO(tutorial: .dragToRearrange,
            instructionText: "Press and hold on a cell in the play queue to rearrange",
            nextTutorial: nil))
        
        var map = [Tutorial:TutorialDTO]()
        for dto in tutorials {
            map[dto.tutorial] = dto
        }
        return map
    }()
    
    weak var presentedTutorial:TutorialViewController?

    func dimissTutorials(_ tutorials:[Tutorial], action:TutorialAction) {
        for tutorial in tutorials {
            if dismissTutorial(tutorial, action: action){
                break
            }
        }
    }
	
	@discardableResult
    func dismissTutorial(_ tutorial:Tutorial, action:TutorialAction) -> Bool {
        guard let tvc = presentedTutorial , tvc.tutorialDTO.tutorial == tutorial else {
            return false
        }
        
        switch action {
        case .dismissFulfilled, .fulfill:
            setFulfulled(tutorial, fulfilled: true)
            break
        case .dismissUnfulfilled:
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
	
    private func setFulfulled(_ tutorial:Tutorial, fulfilled:Bool) {
		userDefaults.set(fulfilled, forKey: type(of: self).keyForTutorial(tutorial))
	}
    
    //use this function when the intention is to present one of many
    //unfulfilled tutorials in the same invocation
	@discardableResult
    func presentUnfulfilledTutorials(_ tutorials:[Tutorial]) -> Bool {
        for tutorial in tutorials {
            if presentTutorialIfUnfulfilled(tutorial) {
				return true
            }
        }
		return false
    }
	
	@discardableResult
	func presentTutorialIfUnfulfilled(_ tutorial:Tutorial) -> Bool {
        guard !tutorialIsFulfilled(tutorial)
            && !KyoozUtils.screenshotUITesting else {
            return false
        }
        
        if let tvc = presentedTutorial {
            if tvc.tutorialDTO.tutorial == tutorial {
                return true
            } else {
                //this dismisses the presenting tutorial when a new one is requested to be shown
                _ = dismissTutorial(tvc.tutorialDTO.tutorial, action: .dismissUnfulfilled)
            }
        }
        
        guard let dto = tutorialDataMap[tutorial] else {
            fatalError("no tutorial defined for \(tutorial)")
        }
        
        let tvc:TutorialViewController = tutorialViewControllerFactory.viewControllerForTutorial(dto)
		_ = ConstraintUtils.applyStandardConstraintsToView(subView: tvc.view, parentView: presentationController.view)
		presentationController.addChildViewController(tvc)
		tvc.didMove(toParentViewController: presentationController)
        presentedTutorial = tvc
        return true
	}
	
	private func tutorialIsFulfilled(_ tutorial:Tutorial) -> Bool {
		return userDefaults.bool(forKey: type(of: self).keyForTutorial(tutorial))
	}
	
    static func keyForTutorial(_ tutorial:Tutorial) -> String {
		return "\(userDefaultKeyPrefix)\(tutorial)"
	}
    
    
	
}
