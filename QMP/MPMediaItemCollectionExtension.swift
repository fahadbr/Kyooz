//
//  MPMediaItemCollectionExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/17/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

extension MPMediaItemCollection {

    //overriding this so that collections can be searched by their underlying track properties
    override public func valueForUndefinedKey(key: String) -> AnyObject? {
        return self.representativeItem?.valueForProperty(key)
    }
    
}
