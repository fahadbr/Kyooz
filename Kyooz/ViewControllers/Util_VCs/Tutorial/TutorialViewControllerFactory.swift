//
//  TutorialViewControllerFactory.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/15/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class TutorialViewControllerFactory {
    
    func viewControllerForTutorial(_ dto:TutorialDTO) -> TutorialViewController {
        
        switch dto.tutorial {
        case .gestureActivatedSearch:
            return PanTutorialViewController(tutorialDTO: dto, isPanningRight: true)
        case .gestureToViewQueue:
            return PanTutorialViewController(tutorialDTO: dto, isPanningRight: false)
		case .dragAndDrop:
			return LongPressTutorialViewController(tutorialDTO: dto)
        case .dragToRearrange:
            return DragToRearrangeTutorialViewController(tutorialDTO: dto)
        default:
            return NoAnimationTutorialViewController(tutorialDTO: dto)
        }
        
    }
    
}
