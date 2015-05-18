//
//  GestureHandler.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

protocol GestureHandler : NSObjectProtocol {
    
    typealias GestureRecognizerType:UIGestureRecognizer
    
    func handleGesture(sender:GestureRecognizerType)
    
}

@objc protocol GestureHandlerDelegate {
    
    optional func gestureDidBegin(sender:UIGestureRecognizer)
    
    optional func gestureDidChange(sender:UIGestureRecognizer)
    
    optional func gestureDidEnd(sender:UIGestureRecognizer)
    
}