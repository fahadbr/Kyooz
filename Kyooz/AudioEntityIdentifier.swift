//
//  AudioTrackIdentifier.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/6/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

protocol AudioEntityIdentifier {
    
}

extension UInt64 : AudioEntityIdentifier {}
extension String : AudioEntityIdentifier {}


func ==(rhs:AudioEntityIdentifier, lhs:AudioEntityIdentifier) -> Bool{

    if let right = rhs as? UInt64, let left = lhs as? UInt64 {
        return right == left
    }
    if let right = rhs as? String, let left = lhs as? String {
        return right == left
    }
    return false
}