//
//  TutorialViewControllerFactory.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/15/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class TutorialViewControllerFactory {
    
    func viewControllerForTutorial(dto:TutorialDTO) -> TutorialViewController {
        
        switch dto.tutorial {
        case .GestureActivatedSearch:
            return PanTutorialViewController(tutorialDTO: dto, isPanningRight: true)
        case .GestureToViewQueue:
            return PanTutorialViewController(tutorialDTO: dto, isPanningRight: false)
        default:
            return TutorialViewController(tutorialDTO:dto)
        }
        
    }
    
}
