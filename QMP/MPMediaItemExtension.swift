//
//  MPMediaItemExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/18/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

extension MPMediaItem :Equatable {
    
}

public func ==(lhs:MPMediaItem, rhs:MPMediaItem) -> Bool {
    return lhs.persistentID == rhs.persistentID
}