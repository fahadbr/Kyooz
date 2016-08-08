//
//  Tutorial.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/12/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation


enum Tutorial : Int , EnumNameDescriptable {
	
    case gestureActivatedSearch
    case gestureToViewQueue
    case dragAndDrop
    case insertOrCancel
    case dragToRearrange
	
}

enum TutorialAction : Int {
    case fulfill, dismissUnfulfilled, dismissFulfilled
}

struct TutorialDTO {

    let tutorial:Tutorial
    let instructionText:String
    let nextTutorial:Tutorial?
    
}

