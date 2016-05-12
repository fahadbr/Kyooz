//
//  Tutorial.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/12/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation


enum Tutorial : Int {
	
	private static let instructionMap:[Tutorial:String] = [.DragAndDrop:"Press and hold to drag, let go to drop"
		.GestureActivatedSearch : "",
		.GestureToViewQueue: ""]
	
	case DragAndDrop, GestureActivatedSearch, GestureToViewQueue
	
	
	
}
