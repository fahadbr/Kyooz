//
//  Tutorial.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/12/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation


enum Tutorial : Int , EnumNameDescriptable {
	
    case GestureActivatedSearch
    case GestureToViewQueue
    case DragAndDrop
    case InsertOrCancel
    case DragToRearrange
	
}

enum TutorialAction : Int {
    case Fulfill, DismissUnfulfilled, DismissFulfilled
}

struct TutorialDTO {

    let tutorial:Tutorial
    let instructionText:String
    let nextTutorial:Tutorial?
    
}

