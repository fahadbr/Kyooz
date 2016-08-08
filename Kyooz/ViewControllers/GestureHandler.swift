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
    
    associatedtype GestureRecognizerType:UIGestureRecognizer
    
    func handleGesture(_ sender:GestureRecognizerType)
    
}

@objc protocol GestureHandlerDelegate {
    
    @objc optional func gestureDidBegin(_ sender:UIGestureRecognizer)
    
    @objc optional func gestureDidEnd(_ sender:UIGestureRecognizer)
    
}
