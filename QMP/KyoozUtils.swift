//
//  KyoozUtils.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 11/15/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

struct KyoozUtils {
    
    static func getDispatchTimeForSeconds(seconds:Double) -> dispatch_time_t {
        return dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
    }
    
}