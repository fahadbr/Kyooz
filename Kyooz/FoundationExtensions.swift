//
//  FoundationExtensions.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/25/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

extension NSIndexPath : Comparable {}

public func <(lhs:NSIndexPath, rhs:NSIndexPath) -> Bool {
    return lhs.compare(rhs) == .OrderedAscending
}

public func ==(lhs:NSIndexPath, rhs:NSIndexPath) -> Bool {
    return lhs.compare(rhs) == .OrderedSame
}

