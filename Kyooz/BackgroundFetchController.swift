//
//  BackgroundFetchController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/16/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class BackgroundFetchController {
    
    static let instance = BackgroundFetchController()
    
    var playCountIterator:PlayCountIterator?
    
    func performFetchWithCompletionHandler(_ completionHandler: (UIBackgroundFetchResult) -> Void) {
        playCountIterator?.performBackgroundIteration(completionHandler)
    }
    
}
