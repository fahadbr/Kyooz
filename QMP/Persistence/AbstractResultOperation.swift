//
//  AbstractResultOperation.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/22/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation


class AbstractResultOperation<T> : NSOperation {
    
    var inThreadCompletionBlock:((T)->())?
    
    override func main() {
        fatalError("main method must be overriden")
    }
    
}